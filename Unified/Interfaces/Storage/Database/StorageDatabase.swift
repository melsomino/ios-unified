//
// Created by Власов М.Ю. on 17.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation

public protocol StorageDatabase {
	func tableExists(tableName: String) -> Bool
	func createSelectStatement(sql: String) throws -> DatabaseSelectStatement
	func createUpdateStatement(sql: String) throws -> DatabaseUpdateStatement
	func executeStatement(sql: String) throws

}
