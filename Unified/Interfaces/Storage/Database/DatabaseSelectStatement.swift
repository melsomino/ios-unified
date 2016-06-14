//
// Created by Власов М.Ю. on 17.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation

public protocol DatabaseSelectStatement: DatabaseStatement {
	func execute() throws -> DatabaseReader
}
