//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import GRDB

open class DefaultModuleStorage: ModuleStorage {

	init(moduleName: String) {
		self.moduleName = moduleName
	}



	open func switchToAccount(_ accountName: String?) {
		lock.lock()
		defer {
			lock.unlock()
		}
		guard !String.same(accountName, self.accountName) else {
			return
		}
		self.accountName = accountName
		currentPlatformDatabase = nil
	}


	// MARK: - ModuleStorage

	open func initializeDatabase(_ maintenance: DatabaseMaintenance) {
		databaseMaintenance = maintenance
		databaseInitialized = false
	}



	open func getFileStoragePath(_ relativePath: String) -> String {
		do {
			return try ensureDirectoryPath("Files/\(relativePath)")
		}
			catch let error {
			fatalError(String(describing: error))
		}
	}



	open func readDatabase(_ read: (StorageDatabase) throws -> Void) throws {
		try platformDatabase.read {
			db in try read(DefaultModuleDatabase(db))
		}
	}



	open func writeDatabaseWithoutTransaction(_ write: (StorageDatabase) throws -> Void) throws {
		try platformDatabase.write {
			db in try write(DefaultModuleDatabase(db))
		}
	}



	open func writeDatabase(_ write: (StorageDatabase) throws -> Void) throws {
		try platformDatabase.inTransaction(.immediate) {
			db in
			let moduleDatabase = DefaultModuleDatabase(db)
			try write(moduleDatabase)
			return .commit
		}
	}


	// MARK: - Internals


	private var lock = NSRecursiveLock()
	private var threading: Threading!
	private let moduleName: String
	private var accountName: String?
	private var databaseMaintenance: DatabaseMaintenance?
	private var databaseInitialized = false

	private var currentPlatformDatabase: DatabaseQueue?
	private var platformDatabase: DatabaseQueue {
		lock.lock()
		defer {
			lock.unlock()
		}
		if let database = currentPlatformDatabase {
			return database
		}

		do {
			guard accountName != nil else {
				throw StorageError(message: "Can not initialize database for module \"\(moduleName)\": storage does not bound to account name")
			}
			guard let maintenance = databaseMaintenance else {
				throw StorageError(message: "Can not initialize database for module \"\(moduleName)\": database maintenance is not specified")
			}
			let newDatabase = try DatabaseQueue(path: self.ensureDirectoryPath("") + "/Database.sqlite")
			try upgradeDatabaseIfNeeded(newDatabase, maintenance: maintenance)
			currentPlatformDatabase = newDatabase
		}
			catch let error {
			fatalError(String(describing: error))
		}

		return currentPlatformDatabase!
	}

	private func upgradeDatabaseIfNeeded(_ platformConnection: DatabaseQueue, maintenance: DatabaseMaintenance) throws {
		try platformConnection.write {
			platformDatabase in
			let database = DefaultModuleDatabase(platformDatabase)
			if let info = try self.selectDatabaseInfo(database) {
				if info.databaseVersion != maintenance.requiredVersion {
					if !(try maintenance.migrate(database: database, fromVersion: info.databaseVersion)) {
						try maintenance.createTables(database: database)
					}
				}
				try self.updateDatabaseInfo(database, DatabaseInfoRecord(databaseVersion: maintenance.requiredVersion))
				return
			}
			try maintenance.createTables(database: database)
			try self.createDatabaseInfo(database, DatabaseInfoRecord(databaseVersion: maintenance.requiredVersion))
		}
	}



	private func ensureDirectoryPath(_ relativePath: String) throws -> String {
		guard !(accountName ?? "").isEmpty else {
			fatalError("Required storage access failed due to missing account")
		}
		let appDataPath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0]
		let path = "\(appDataPath)/\(accountName ?? "")/\(moduleName)/\(relativePath)"
		try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
		return path
	}

	open class DatabaseInfoRecord {
		open var databaseVersion: Int
		init() {
			databaseVersion = 0
		}

		init(databaseVersion: Int) {
			self.databaseVersion = databaseVersion
		}
	}

	open var databaseInfoTable: String {
		return "__\(moduleName)"
	}


	private func selectDatabaseInfo(_ database: StorageDatabase) throws -> DatabaseInfoRecord? {
		guard try database.tableExists(databaseInfoTable) else {
			return nil
		}
		return try DatabaseRecordReader(database: database,
			sql: "SELECT databaseVersion FROM \(databaseInfoTable)",
			record: DatabaseInfoRecord(),
			setParams: { select in },
			readRecord: { $1.databaseVersion = $0.getInteger(0) ?? 0 }).next()
	}



	private func updateDatabaseInfo(_ database: StorageDatabase, _ info: DatabaseInfoRecord) throws {
		let update = try database.createUpdateStatement("UPDATE \(databaseInfoTable) SET databaseVersion=?")
		defer {
			update.close()
		}
		update.setInteger(0, info.databaseVersion)
		try update.execute()
	}



	private func createDatabaseInfo(_ database: StorageDatabase, _ info: DatabaseInfoRecord) throws {

		try database.executeStatement("CREATE TABLE \(databaseInfoTable) (databaseVersion INT)")
		let insert = try database.createUpdateStatement("INSERT INTO \(databaseInfoTable)(databaseVersion) VALUES (?)")
		defer {
			insert.close()
		}
		insert.setInteger(0, info.databaseVersion)
		try insert.execute()
	}


}
