//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public protocol DatabaseStatement {
	func reset()
	func close()

	func setNull(_ index: Int)
	func setUuid(_ index: Int, _ value: Uuid?)
	func setString(_ index: Int, _ value: String?)
	func setInteger(_ index: Int, _ value: Int?)
	func setDateTime(_ index: Int, _ value: Date?)
	func setDouble(_ index: Int, _ value: Double?)
	func setBlob(_ index: Int, _ value: Data?)
	func setBoolean(_ index: Int, _ value: Bool?)

}
