//
// Created by Michael Vlasov on 27.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
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


extension NSScanner {

	convenience init(source: String, passWhitespaces: Bool) {
		self.init(string: source)
		charactersToBeSkipped = nil
		if passWhitespaces {
			self.passWhitespaces()
		}
	}


	func passWhitespaces() {
		scanCharactersFromSet(NSCharacterSet.whitespaceCharacterSet(), intoString: nil)
	}


	func pass(expected: String, passWhitespaces: Bool) -> Bool {
		let passed = scanString(expected, intoString: nil)
		if passed && passWhitespaces {
			self.passWhitespaces()
		}
		return passed
	}


	func passCharachters(charachters: NSCharacterSet, passWhitespaces: Bool) -> String? {
		var passed: NSString?
		if scanCharactersFromSet(charachters, intoString: &passed) {
			if passWhitespaces {
				self.passWhitespaces()
			}
			return String(passed!)
		}
		return nil
	}


	func expect(expected: String, passWhitespaces: Bool) throws {
		if !pass(expected, passWhitespaces: passWhitespaces) {
			throw DeclarationError(message: "\(expected) expected", scanner: self)
		}
	}


	func passIdentifier(passWhitespaces passWhitespaces: Bool) -> String? {
		var start: NSString?
		guard scanCharactersFromSet(NSScanner.identifierStart, intoString: &start) else {
			return nil
		}
		var identifier = String(start!)
		var rest: NSString?
		if scanCharactersFromSet(NSScanner.identifierRest, intoString: &rest) {
			identifier += String(rest!)
		}
		if passWhitespaces {
			self.passWhitespaces()
		}
		return identifier
	}


	func expectIdentifier(passWhitespaces passWhitespaces: Bool) throws -> String {
		guard let passed = passIdentifier(passWhitespaces: passWhitespaces) else {
			throw DeclarationError(message: "identifier expected", scanner: self)
		}
		return passed
	}


	func passFloat(passWhitespaces passWhitespaces: Bool) -> CGFloat? {
		var value: Float = 0
		guard scanFloat(&value) else {
			return nil
		}
		if passWhitespaces {
			self.passWhitespaces()
		}
		return CGFloat(value)
	}


	func passUntil(terminator: String) -> String? {
		var value: NSString?
		return scanUpToString(terminator, intoString: &value) ? String(value!) : nil
	}


	func passUntilEndOrOneOf(terminator: NSCharacterSet, passWhitespaces: Bool) -> String? {
		var value: NSString?
		if scanUpToCharactersFromSet(terminator, intoString: &value) {
			if passWhitespaces {
				self.passWhitespaces()
			}
			return String(value!)
		}
		return nil
	}


	func expectUntil(terminator: String) throws -> String {
		guard let passed = passUntil(terminator) else {
			throw DeclarationError(message: "can not find terminator \"\(terminator)\"", scanner: self)
		}
		return passed
	}

	private static let identifierStart = NSCharacterSet.union(NSCharacterSet.letterCharacterSet(), NSCharacterSet(charactersInString: "_"))
	private static let identifierRest = NSCharacterSet.union(identifierStart, NSCharacterSet.decimalDigitCharacterSet())

}


extension NSCharacterSet {

	static func union(sets: NSCharacterSet...) -> NSCharacterSet {
		let builder = sets[0].mutableCopy() as! NSMutableCharacterSet
		for i in 1 ..< sets.count {
			builder.formUnionWithCharacterSet(sets[i])
		}
		return builder.copy() as! NSCharacterSet
	}
}

