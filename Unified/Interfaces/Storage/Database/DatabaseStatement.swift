//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public protocol DatabaseStatement {
	func reset()
	func close()

	func setNull(index: Int)
	func setUuid(index: Int, _ value: Uuid?)
	func setString(index: Int, _ value: String?)
	func setInteger(index: Int, _ value: Int?)
	func setDateTime(index: Int, _ value: NSDate?)
	func setDouble(index: Int, _ value: Double?)
	func setBlob(index: Int, _ value: NSData?)
	func setBoolean(index: Int, _ value: Bool?)

}
