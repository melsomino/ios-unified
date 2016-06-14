//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import GRDB

public class DefaultDatabaseUpdateStatement: DefaultDatabaseStatement, DatabaseUpdateStatement {

	init(_ platformStatement: UpdateStatement) {
		super.init(platformStatement)
	}


	// MARK: - DatabaseUpdateStatement

	public func execute() throws {
		try (platformStatement as! UpdateStatement).execute(arguments: StatementArguments(arguments))
	}



}
