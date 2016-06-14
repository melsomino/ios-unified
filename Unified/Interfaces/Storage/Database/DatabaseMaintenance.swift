//
// Created by Власов М.Ю. on 17.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation

public protocol DatabaseMaintenance {
	var requiredVersion: Int { get }
	func createTables(database: StorageDatabase) throws
	func migrate(database: StorageDatabase, fromVersion: Int) throws -> Bool
}
