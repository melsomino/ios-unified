//
// Created by Власов М.Ю. on 17.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import GRDB

public class DefaultDatabaseSelectStatement : DefaultDatabaseStatement, DatabaseSelectStatement {


	init(_ platformStatement: SelectStatement) {
		super.init(platformStatement)
	}

	// MARK: - DatabaseSelectStatement

	public func execute() throws -> DatabaseReader {
		return DefaultDatabaseReader(try executeSelect())
	}



}
