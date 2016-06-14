//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public protocol DatabaseReader {
	func close()
	func read() -> Bool

	func isNull(index: Int) -> Bool
	func getString(index: Int) -> String?
	func getUuid(index: Int) -> UUID?
	func getInteger(index: Int) -> Int?
	func getDateTime(index: Int) -> NSDate?
	func getDouble(index: Int) -> Double?
	func getBlob(index: Int) -> NSData?
	func getBoolean(index: Int) -> Bool?
}
