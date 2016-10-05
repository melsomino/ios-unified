//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public protocol DatabaseReader {
	func close()
	func read() -> Bool

	func isNull(_ index: Int) -> Bool
	func getString(_ index: Int) -> String?
	func getUuid(_ index: Int) -> Uuid?
	func getInteger(_ index: Int) -> Int?
	func getDateTime(_ index: Int) -> Date?
	func getDouble(_ index: Int) -> Double?
	func getBlob(_ index: Int) -> Data?
	func getBoolean(_ index: Int) -> Bool?
}
