//
// Created by Michael Vlasov on 12.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public typealias Uuid = UUID

public let UuidZero = NSUUID(uuidBytes: [UInt8](repeating: 0, count: 16)) as UUID



extension Uuid {

	public static func same(_ a: Uuid?, _ b: Uuid?) -> Bool {
		if a == nil && b == nil {
			return true
		}
		if a == nil || b == nil {
			return false
		}
		return a! == b!
	}
}



extension String {

	public func toUuid() -> Uuid? {
		return !isEmpty ? Uuid(uuidString: self) : nil
	}



	public static func fromUuid(_ value: Uuid?) -> String {
		return value != nil ? value!.uuidString : ""
	}
}


