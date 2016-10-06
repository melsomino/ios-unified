//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import GRDB

open class DefaultModuleDatabase: StorageDatabase {

	init(_ platformDatabase: Database) {
		self.platformDatabase = platformDatabase
	}


	// MARK: - ModuleDatabase


	open func tableExists(_ tableName: String) -> Bool {
		return platformDatabase.tableExists(tableName)
	}

	open func createUpdateStatement(_ sql: String) throws -> DatabaseUpdateStatement {
		return DefaultDatabaseUpdateStatement(try platformDatabase.makeUpdateStatement(sql))
	}


	open func createSelectStatement(_ sql: String) throws -> DatabaseSelectStatement {
		return DefaultDatabaseSelectStatement(try platformDatabase.makeSelectStatement(sql))
	}


	open func executeStatement(_ sql: String) throws {
		try platformDatabase.execute(sql)
	}


	// MARK: - Internals


	fileprivate let platformDatabase: Database
}
