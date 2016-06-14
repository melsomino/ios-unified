//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public protocol StorageDatabase {
	func tableExists(tableName: String) -> Bool
	func createSelectStatement(sql: String) throws -> DatabaseSelectStatement
	func createUpdateStatement(sql: String) throws -> DatabaseUpdateStatement
	func executeStatement(sql: String) throws

}
