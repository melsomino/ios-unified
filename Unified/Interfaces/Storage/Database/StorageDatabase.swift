//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public protocol StorageDatabase {
	func tableExists(_ tableName: String) -> Bool
	func createSelectStatement(_ sql: String) throws -> DatabaseSelectStatement
	func createUpdateStatement(_ sql: String) throws -> DatabaseUpdateStatement
	func executeStatement(_ sql: String) throws

}
