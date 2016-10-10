//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public protocol DatabaseMaintenance {
	var requiredVersion: Int { get }
	func createTables(database: StorageDatabase) throws
	func migrate(database: StorageDatabase, fromVersion: Int) throws -> Bool
}
