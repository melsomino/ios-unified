//
//
// Created by Власов М.Ю. on 17.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import GRDB


public class DefaultDatabaseStatement: DatabaseStatement {

	init(_ platformStatement: Statement) {
		self.platformStatement = platformStatement
	}

	public func executeSelect() throws -> DatabaseGenerator<Row> {
		return Row.fetch(platformStatement as! SelectStatement, arguments: StatementArguments(arguments)).generate()
	}

	public func executeUpdate() throws {
		try (platformStatement as! UpdateStatement).execute(arguments: StatementArguments(arguments))

	}

	// MARK: - DatabaseStatement

	public func close() {
	}


	public func reset() {
		arguments.removeAll(keepCapacity: true)
	}


	public func setNull(index: Int) {
		setValue(index, nil)
	}


	public func setUuid(index: Int, _ value: UUID?) {
		setString(index, value?.UUIDString)
	}


	public func setString(index: Int, _ value: String?) {
		setValue(index, value)
	}


	public func setInteger(index: Int, _ value: Int?) {
		setValue(index, value)
	}


	public func setDateTime(index: Int, _ value: NSDate?) {
		setValue(index, value)
	}


	public func setDouble(index: Int, _ value: Double?) {
		setValue(index, value)
	}


	public func setBlob(index: Int, _ value: NSData?) {
		setValue(index, value)
	}


	public func setBoolean(index: Int, _ value: Bool?) {
		setValue(index, value)
	}


	// MARK: - Internals


	public let platformStatement: Statement
	public var arguments = [DatabaseValueConvertible?]()

	func setValue(index: Int, _ value: DatabaseValueConvertible?) {
		while index >= arguments.count {
			arguments.append(nil)
		}
		arguments[index] = value
	}

}
