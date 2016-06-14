//
// Created by Власов М.Ю. on 27.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation


extension Dictionary {
	public mutating func getOrAdd(key: Key, @autoclosure _ createValue: () -> Value) -> Value {
		if let existing = self[key] {
			return existing
		}
		let newValue = createValue()
		self[key] = newValue
		return newValue
	}

}

extension Array {

	public func copyFirst(amount: Int) -> [Element] {
		return self.count <= amount ? self :[Element](prefix(amount))
	}

	func insertionIndexOf(elem: Element, @noescape isOrderedBefore: (Element, Element) -> Bool) -> Int {
		var lo = 0
		var hi = self.count - 1
		while lo <= hi {
			let mid = (lo + hi)/2
			if isOrderedBefore(self[mid], elem) {
				lo = mid + 1
			} else if isOrderedBefore(elem, self[mid]) {
				hi = mid - 1
			} else {
				return mid
			}
		}
		return lo
	}
}


extension NSDate {

	public static func orderOf(a: NSDate?, _ b: NSDate?) -> NSComparisonResult {
		if a == nil && b == nil {
			return .OrderedSame
		}
		if a == nil {
			return .OrderedAscending
		}
		if b == nil {
			return .OrderedDescending
		}
		return a!.compare(b!)
	}

	public static func isOrderedBefore(a: NSDate?, _ b: NSDate?) -> Bool {
		return orderOf(a, b) == .OrderedAscending
	}
}