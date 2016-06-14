//
// Created by Власов М.Ю. on 17.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import GRDB

public class DefaultModuleDatabase: StorageDatabase {

	init(_ platformDatabase: Database) {
		self.platformDatabase = platformDatabase
	}


	// MARK: - ModuleDatabase


	public func tableExists(tableName: String) -> Bool {
		return platformDatabase.tableExists(tableName)
	}

	public func createUpdateStatement(sql: String) throws -> DatabaseUpdateStatement {
		return DefaultDatabaseUpdateStatement(try platformDatabase.updateStatement(sql))
	}


	public func createSelectStatement(sql: String) throws -> DatabaseSelectStatement {
		return DefaultDatabaseSelectStatement(try platformDatabase.selectStatement(sql))
	}


	public func executeStatement(sql: String) throws {
		try platformDatabase.execute(sql)
	}


	// MARK: - Internals


	private let platformDatabase: Database
}
