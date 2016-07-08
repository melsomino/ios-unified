//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import GRDB

public class DefaultDatabaseReader: DatabaseReader {

	init(_ platformReader: DatabaseGenerator<Row>) {
		self.platformReader = platformReader
	}

	// MARK: - DatabaseReader

	public func close() {
	}

	public func read() -> Bool {
		current = self.platformReader.next()
		return current != nil
	}

	public func isNull(index: Int) -> Bool {
		if let databaseValue = current!.value(atIndex: index)?.databaseValue {
			return databaseValue.isNull
		}
		return true
	}

	public func getUuid(index: Int) -> Uuid? {
		let string = getString(index)
		return string != nil ? CloudApiPrimitiveTypeConverter.uuidFromJson(string!) : nil
	}

	public func getString(index: Int) -> String? {
		return current!.value(atIndex: index)
	}

	public func getInteger(index: Int) -> Int? {
		return current!.value(atIndex: index)
	}

	public func getDateTime(index: Int) -> NSDate? {
		return current!.value(atIndex: index)
	}

	public func getDouble(index: Int) -> Double? {
		return current!.value(atIndex: index)
	}

	public func getBlob(index: Int) -> NSData? {
		return current!.value(atIndex: index)
	}

	public func getBoolean(index: Int) -> Bool? {
		return current!.value(atIndex: index)
	}

	// MARK: - Internals

	private let platformReader: DatabaseGenerator<Row>
	private var current: Row?

}
