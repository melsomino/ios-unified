//
// Created by Michael Vlasov on 27.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public func sameObjects(_ a: AnyObject?, _ b: AnyObject?) -> Bool {
	if a == nil && b == nil {
		return true
	}
	if a == nil || b == nil {
		return false
	}
	return a! === b!
}



extension String {
	public static func same(_ a: String?, _ b: String?) -> Bool {
		if a == nil && b == nil {
			return true
		}
		if a == nil || b == nil {
			return false
		}
		return a! == b!
	}
}



extension Error {
	public var userMessage: String {
		switch self {
			case let nsError as NSError:
				return nsError.localizedDescription
			default:
				return String(describing: self)
		}
	}
}



public extension Sequence {

	func find(_ predicate: (Self.Iterator.Element) throws -> Bool) rethrows -> Self.Iterator.Element? {
		for element in self {
			if try predicate(element) {
				return element
			}
		}
		return nil
	}



	func categorise<Key:Hashable, Value>(_ getKey: (Iterator.Element) -> Key, _ getValue: (Iterator.Element) -> Value) -> [Key: [Value]] {
		var result: [Key: [Value]] = [:]
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
	public mutating func getOrAdd(_ key: Key, _ createValue: @autoclosure () -> Value) -> Value {
		if let existing = self[key] {
			return existing
		}
		let newValue = createValue()
		self[key] = newValue
		return newValue
	}

}



extension Array {

	public func copyFirst(_ amount: Int) -> [Element] {
		return self.count <= amount ? self : [Element](prefix(amount))
	}



	func insertionIndexOf(_ elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
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



extension Date {

	public static func orderOf(_ a: Date?, _ b: Date?) -> ComparisonResult {
		if a == nil && b == nil {
			return .orderedSame
		}
		if a == nil {
			return .orderedAscending
		}
		if b == nil {
			return .orderedDescending
		}
		return a!.compare(b!)
	}



	public static func isOrderedBefore(_ a: Date?, _ b: Date?) -> Bool {
		return orderOf(a, b) == .orderedAscending
	}
}



open class ParseError: Error, CustomStringConvertible {
	open var message: String
	open var scanner: Scanner

	public init(_ message: String, _ scanner: Scanner) {
		self.message = message
		self.scanner = scanner
	}

	// MARK: - CustomStringConvertible

	open var description: String {
		return "\(message) at: \(scanner.string.substring(from: scanner.string.characters.index(scanner.string.startIndex, offsetBy: scanner.scanLocation)))"
	}

}



extension Scanner {

	convenience init(source: String, passWhitespaces: Bool) {
		self.init(string: source)
		charactersToBeSkipped = nil
		if passWhitespaces {
			self.passWhitespaces()
		}
	}



	func passWhitespaces() {
		scanCharacters(from: CharacterSet.whitespaces, into: nil)
	}



	func pass(_ expected: String, passWhitespaces: Bool) -> Bool {
		let passed = scanString(expected, into: nil)
		if passed && passWhitespaces {
			self.passWhitespaces()
		}
		return passed
	}



	func pass(_ expected: String) -> Bool {
		return pass(expected, passWhitespaces: false)
	}



	func expect(_ expected: String, passWhitespaces: Bool) throws {
		if !pass(expected, passWhitespaces: passWhitespaces) {
			throw ParseError("\(expected) expected", self) as Error
		}
	}



	func passCharacters(_ expected: CharacterSet, passWhitespaces: Bool) -> String? {
		var passed: NSString?
		if scanCharacters(from: expected, into: &passed) {
			if passWhitespaces {
				self.passWhitespaces()
			}
			return String(passed!)
		}
		return nil
	}



	func passCharacters(_ expected: CharacterSet) -> String? {
		return passCharacters(expected, passWhitespaces: false)
	}



	func expectCharacters(_ expected: CharacterSet, passWhitespaces: Bool, expectedDescription: String) throws -> String {
		if let passed = passCharacters(expected, passWhitespaces: passWhitespaces) {
			return passed
		}
		throw ParseError("\(expectedDescription) expected", self) as Error
	}



	func expectCharacters(_ expected: CharacterSet, expectedDescription: String) throws -> String {
		return try expectCharacters(expected, passWhitespaces: false, expectedDescription: expectedDescription)
	}



	func passIdentifier(passWhitespaces: Bool) -> String? {
		var start: NSString?
		guard scanCharacters(from: Scanner.identifierStart, into: &start) else {
			return nil
		}
		var identifier = String(start!)
		var rest: NSString?
		if scanCharacters(from: Scanner.identifierRest, into: &rest) {
			identifier += String(rest!)
		}
		if passWhitespaces {
			self.passWhitespaces()
		}
		return identifier
	}



	func expectIdentifier(passWhitespaces: Bool) throws -> String {
		guard let passed = passIdentifier(passWhitespaces: passWhitespaces) else {
			throw ParseError("identifier expected", self) as Error
		}
		return passed
	}



	func passFloat(passWhitespaces: Bool) -> CGFloat? {
		var value: Float = 0
		guard scanFloat(&value) else {
			return nil
		}
		if passWhitespaces {
			self.passWhitespaces()
		}
		return CGFloat(value)
	}



	func passUntil(_ terminator: String) -> String? {
		var value: NSString?
		return scanUpTo(terminator, into: &value) ? String(value!) : nil
	}



	func passUntilEndOrOneOf(_ terminator: CharacterSet, passWhitespaces: Bool) -> String? {
		var value: NSString?
		if scanUpToCharacters(from: terminator, into: &value) {
			if passWhitespaces {
				self.passWhitespaces()
			}
			return String(value!)
		}
		return nil
	}



	func expectUntil(_ terminator: String) throws -> String {
		guard let passed = passUntil(terminator) else {
			throw ParseError("can not find terminator \"\(terminator)\"", self) as Error
		}
		return passed
	}

	private static let identifierStart = CharacterSet.union(CharacterSet.letters, CharacterSet(charactersIn: "_"))
	private static let identifierRest = CharacterSet.union(identifierStart, CharacterSet.decimalDigits)

}



extension CharacterSet {

	static func union(_ sets: CharacterSet...) -> CharacterSet {
		let builder = (sets[0] as NSCharacterSet).mutableCopy() as! NSMutableCharacterSet
		for i in 1 ..< sets.count {
			builder.formUnion(with: sets[i])
		}
		return builder.copy() as! CharacterSet
	}
}



extension Bundle {

	private static let bundleIdByModuleName: [String: String] = {
		var bundles = [String: String]()
		for bundle in Bundle.allBundles {
			if let id = bundle.bundleIdentifier {
				let idParts = id.components(separatedBy: ".")
				let moduleName = idParts[idParts.count - 1]
				bundles[moduleName] = id
			}
		}
		for bundle in Bundle.allFrameworks {
			if let id = bundle.bundleIdentifier {
				let idParts = id.components(separatedBy: ".")
				let moduleName = idParts[idParts.count - 1]
				bundles[moduleName] = id
			}
		}
		return bundles
	}()

	public static func fromModuleName(_ moduleName: String) -> Bundle? {
		let id = bundleIdByModuleName[moduleName]
		return id != nil ? Bundle(identifier: id!) : nil
	}



	public static func requiredFromModuleName(_ moduleName: String) -> Bundle {
		if let bundle = fromModuleName(moduleName) {
			return bundle
		}
		fatalError("Can'not find bundle with module name [\(moduleName)]")
	}


}
