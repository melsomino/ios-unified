//
//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import GRDB


open class DefaultDatabaseStatement: DatabaseStatement {

	init(_ platformStatement: Statement) {
		self.platformStatement = platformStatement
	}

	open func executeSelect() throws -> DatabaseIterator<Row> {
		return Row.fetch(platformStatement as! SelectStatement, arguments: StatementArguments(arguments)).makeIterator()
	}

	open func executeUpdate() throws {
		try (platformStatement as! UpdateStatement).execute(arguments: StatementArguments(arguments))

	}

	// MARK: - DatabaseStatement

	open func close() {
	}


	open func reset() {
		arguments.removeAll(keepingCapacity: true)
	}


	open func setNull(_ index: Int) {
		setValue(index, nil)
	}


	open func setUuid(_ index: Int, _ value: Uuid?) {
		setString(index, value?.uuidString)
	}


	open func setString(_ index: Int, _ value: String?) {
		setValue(index, value)
	}


	open func setInteger(_ index: Int, _ value: Int?) {
		setValue(index, value)
	}


	open func setDateTime(_ index: Int, _ value: Date?) {
		setValue(index, value)
	}


	open func setDouble(_ index: Int, _ value: Double?) {
		setValue(index, value)
	}


	open func setBlob(_ index: Int, _ value: Data?) {
		setValue(index, value)
	}


	open func setBoolean(_ index: Int, _ value: Bool?) {
		setValue(index, value)
	}


	// MARK: - Internals


	open let platformStatement: Statement
	open var arguments = [DatabaseValueConvertible?]()

	func setValue(_ index: Int, _ value: DatabaseValueConvertible?) {
		while index >= arguments.count {
			arguments.append(nil)
		}
		arguments[index] = value
	}

}
