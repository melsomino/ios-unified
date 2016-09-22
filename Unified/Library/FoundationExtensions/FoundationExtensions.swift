//
// Created by Michael Vlasov on 27.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public func sameObjects(a: AnyObject?, _ b: AnyObject?) -> Bool {
	if a == nil && b == nil {
		return true
	}
	if a == nil || b == nil {
		return false
	}
	return a! === b!
}

extension String {
	public static func same(a: String?, _ b: String?) -> Bool {
		if a == nil && b == nil {
			return true
		}
		if a == nil || b == nil {
			return false
		}
		return a! == b!
	}
}

public extension SequenceType {

	func categorise<Key:Hashable, Value>(@noescape getKey: Generator.Element -> Key, @noescape _ getValue: Generator.Element -> Value) -> [Key:[Value]] {
		var result: [Key:[Value]] = [:]
		for item in self {
			let key = getKey(item)
			let value = getValue(item)
			if case nil = result[key]?.append(value) {
				result[key] = [value]
			}
		}
		return result
	}
}




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
		return self.count <= amount ? self : [Element](prefix(amount))
	}



	func insertionIndexOf(elem: Element, @noescape isOrderedBefore: (Element, Element) -> Bool) -> Int {
		var lo = 0
		var hi = self.count - 1
		while lo <= hi {
			let mid = (lo + hi) / 2
			if isOrderedBefore(self[mid], elem) {
				lo = mid + 1
			}
			else if isOrderedBefore(elem, self[mid]) {
				hi = mid - 1
			}
			else {
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


public class ParseError: ErrorType, CustomStringConvertible {
	public var message: String
	public var scanner: NSScanner

	public init(_ message: String, _ scanner: NSScanner) {
		self.message = message
		self.scanner = scanner
	}

	// MARK: - CustomStringConvertible

	public var description: String {
		return "\(message) at: \(scanner.string.substringFromIndex(scanner.string.startIndex.advancedBy(scanner.scanLocation)))"
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



	func pass(expected: String) -> Bool {
		return pass(expected, passWhitespaces: false)
	}



	func expect(expected: String, passWhitespaces: Bool) throws {
		if !pass(expected, passWhitespaces: passWhitespaces) {
			throw ParseError("\(expected) expected", self)
		}
	}



	func passCharacters(expected: NSCharacterSet, passWhitespaces: Bool) -> String? {
		var passed: NSString?
		if scanCharactersFromSet(expected, intoString: &passed) {
			if passWhitespaces {
				self.passWhitespaces()
			}
			return String(passed!)
		}
		return nil
	}



	func passCharacters(expected: NSCharacterSet) -> String? {
		return passCharacters(expected, passWhitespaces: false)
	}



	func expectCharacters(expected: NSCharacterSet, passWhitespaces: Bool, expectedDescription: String) throws -> String {
		if let passed = passCharacters(expected, passWhitespaces: passWhitespaces) {
			return passed
		}
		throw ParseError("\(expectedDescription) expected", self)
	}



	func expectCharacters(expected: NSCharacterSet, expectedDescription: String) throws -> String {
		return try expectCharacters(expected, passWhitespaces: false, expectedDescription: expectedDescription)
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
			throw ParseError("identifier expected", self)
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
			throw ParseError("can not find terminator \"\(terminator)\"", self)
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



extension NSBundle {

	private static let bundleIdByModuleName: [String:String] = {
		var bundles = [String: String]()
		for bundle in NSBundle.allBundles() {
			if let id = bundle.bundleIdentifier {
				let idParts = id.componentsSeparatedByString(".")
				let moduleName = idParts[idParts.count - 1]
				bundles[moduleName] = id
			}
		}
		for bundle in NSBundle.allFrameworks() {
			if let id = bundle.bundleIdentifier {
				let idParts = id.componentsSeparatedByString(".")
				let moduleName = idParts[idParts.count - 1]
				bundles[moduleName] = id
			}
		}
		return bundles
	}()

	public static func fromModuleName(moduleName: String) -> NSBundle? {
		let id = bundleIdByModuleName[moduleName]
		return id != nil ? NSBundle(identifier: id!) : nil
	}



	public static func requiredFromModuleName(moduleName: String) -> NSBundle {
		if let bundle = fromModuleName(moduleName) {
			return bundle
		}
		fatalError("Can'not find bundle with module name [\(moduleName)]")
	}


}