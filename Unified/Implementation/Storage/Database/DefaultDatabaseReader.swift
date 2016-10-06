//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import GRDB

open class DefaultDatabaseReader: DatabaseReader {

	init(_ platformReader: DatabaseIterator<Row>) {
		self.platformReader = platformReader
	}

	// MARK: - DatabaseReader

	open func close() {
	}

	open func read() -> Bool {
		current = self.platformReader.next()
		return current != nil
	}

	open func isNull(_ index: Int) -> Bool {
		if let databaseValue = current!.value(atIndex: index)?.databaseValue {
			return databaseValue.isNull
		}
		return true
	}

	open func getUuid(_ index: Int) -> Uuid? {
		let string = getString(index)
		return string != nil ? string!.toUuid() : nil
	}

	open func getString(_ index: Int) -> String? {
		return current!.value(atIndex: index)
	}

	open func getInteger(_ index: Int) -> Int? {
		return current!.value(atIndex: index)
	}

	open func getDateTime(_ index: Int) -> Date? {
		return current!.value(atIndex: index)
	}

	open func getDouble(_ index: Int) -> Double? {
		return current!.value(atIndex: index)
	}

	open func getBlob(_ index: Int) -> Data? {
		return current!.value(atIndex: index)
	}

	open func getBoolean(_ index: Int) -> Bool? {
		return current!.value(atIndex: index)
	}

	// MARK: - Internals

	fileprivate let platformReader: DatabaseIterator<Row>
	fileprivate var current: Row?

}
