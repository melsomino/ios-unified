//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import GRDB

public class DefaultModuleStorage: ModuleStorage {

	init(moduleName: String) {
		self.moduleName = moduleName
	}


	public func switchToAccount(accountName: String?) {
		self.accountName = accountName
		databaseInitialized = false
	}


	// MARK: - ModuleStorage

	public func initializeDatabase(maintenance: DatabaseMaintenance) {
		databaseMaintenance = maintenance
		databaseInitialized = false
	}


	public func getFileStoragePath(relativePath: String) -> String {
		return ensureDirectoryPath("Files/\(relativePath)")
	}

	public func readDatabase(read: (StorageDatabase) throws -> Void) throws {
		try databaseRequired()
		try platformDatabase.read {
			db in try read(DefaultModuleDatabase(db))
		}
	}

	public func writeDatabaseWithoutTransaction(write: (StorageDatabase) throws -> Void) throws {
		try databaseRequired()
		try platformDatabase.write {
			db in try write(DefaultModuleDatabase(db))
		}
	}

	public func writeDatabase(write: (StorageDatabase) throws -> Void) throws {
		try databaseRequired()
		try platformDatabase.writeInTransaction(.Immediate) {
			db in
			let moduleDatabase = DefaultModuleDatabase(db)
			try write(moduleDatabase)
			return .Commit
		}
	}


	// MARK: - Internals


	private var threading: Threading!
	private let moduleName: String
	private var accountName: String?
	private var databaseMaintenance: DatabaseMaintenance?
	private var databaseInitialized = false

	private lazy var platformDatabase: DatabasePool = {
		[unowned self] in
		return try! DatabasePool(path: self.ensureDirectoryPath("") + "/Database.sqlite")
	}()

	private func ensureDirectoryPath(relativePath: String) -> String {
		guard !(accountName ?? "").isEmpty else {
			fatalError("Required storage access failed due to missing account")
		}
		let appDataPath = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)[0]
		let path = "\(appDataPath)/\(accountName ?? "")/\(moduleName)/\(relativePath)"
		try! NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
		return path
	}

	public class DatabaseInfoRecord {
		public var databaseVersion: Int
		init() {
			databaseVersion = 0
		}

		init(databaseVersion: Int) {
			self.databaseVersion = databaseVersion
		}
	}

	private func databaseRequired() throws {
		if databaseInitialized {
			return
		}
		guard accountName != nil else {
			throw StorageError(message: "Can not initialize database for module \"\(moduleName)\": storage does not bound to account name")
		}
		guard let maintenance = databaseMaintenance else {
			throw StorageError(message: "Can not initialize database for module \"\(moduleName)\": database maintenance is not specified")
		}

		try! platformDatabase.write {
			platformDatabase in
			let database = DefaultModuleDatabase(platformDatabase)
			if let info = try self.selectDatabaseInfo(database) {
				if info.databaseVersion != maintenance.requiredVersion {
					if !(try maintenance.migrate(database, fromVersion: info.databaseVersion)) {
						try maintenance.createTables(database)
					}
				}
				try self.updateDatabaseInfo(database, DatabaseInfoRecord(databaseVersion: maintenance.requiredVersion))
				return
			}
			try maintenance.createTables(database)
			try self.createDatabaseInfo(database, DatabaseInfoRecord(databaseVersion: maintenance.requiredVersion))
		}
		databaseInitialized = true
	}

	public var databaseInfoTable: String {
		return "__\(moduleName)"
	}


	private func selectDatabaseInfo(database: StorageDatabase) throws -> DatabaseInfoRecord? {
		guard database.tableExists(databaseInfoTable) else {
			return nil
		}
		return try DatabaseRecordReader(database: database,
			sql: "SELECT databaseVersion FROM \(databaseInfoTable)",
			record: DatabaseInfoRecord(),
			setParams: { select in },
			readRecord: { $1.databaseVersion = $0.getInteger(0) ?? 0 }).next()
	}


	private func updateDatabaseInfo(database: StorageDatabase, _ info: DatabaseInfoRecord) throws {
		let update = try database.createUpdateStatement("UPDATE \(databaseInfoTable) SET databaseVersion=?")
		defer {
			update.close()
		}
		update.setInteger(0, info.databaseVersion)
		try update.execute()
	}


	private func createDatabaseInfo(database: StorageDatabase, _ info: DatabaseInfoRecord) throws {

		try database.executeStatement("CREATE TABLE \(databaseInfoTable) (databaseVersion INT)")
		let insert = try database.createUpdateStatement("INSERT INTO \(databaseInfoTable)(databaseVersion) VALUES (?)")
		defer {
			insert.close()
		}
		insert.setInteger(0, info.databaseVersion)
		try insert.execute()
	}


}
