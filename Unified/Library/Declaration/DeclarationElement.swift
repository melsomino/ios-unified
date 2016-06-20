//
// Created by Власов М.Ю. on 16.06.16.
// Copyright (c) 2016 melsomino. All rights reserved.
//

import Foundation
import UIKit



public struct DeclarationError: ErrorType {
	let message: String
	init(message: String, scanner: NSScanner?) {
		if scanner != nil {
			self.message = "\(message): \(scanner!.string.substringFromIndex(scanner!.string.startIndex.advancedBy(scanner!.scanLocation)))"
		}
		else {
			self.message = message
		}
	}
}





public struct DeclarationAttribute {
	let name: String
	let value: DeclarationValue
}





public struct DeclarationElement {
	public let name: String
	public let attributes: [DeclarationAttribute]
	public let children: [DeclarationElement]


	public static func load(path: String) throws -> [DeclarationElement] {
		let string = try String(contentsOfFile: path, encoding: NSUTF8StringEncoding)
		return try parse(string)
	}


	public static func parse(source: String) throws -> [DeclarationElement] {
		let scanner = NSScanner(source: source, passWhitespaces: false)
		return try parseElements(scanner, elementIndent: 0)
	}


	// MARK: - Internals


	static func parseElement(scanner: NSScanner, elementIndent: Int) throws -> DeclarationElement? {
		guard !scanner.atEnd else {
			return nil
		}

		guard scanner.passDeclarationIndent(elementIndent) else {
			return nil
		}

		let name = (try scanner.expectName(passWhitespaces: true)).lowercaseString
		let attributes = try scanner.parseDeclarationAttributes(elementIndent)
		let children = try parseElements(scanner, elementIndent: elementIndent + 1)

		return DeclarationElement(name: name, attributes: attributes, children: children)
	}


	static func parseElements(scanner: NSScanner, elementIndent: Int) throws -> [DeclarationElement] {
		var elements = [DeclarationElement]()
		while let element = try parseElement(scanner, elementIndent: elementIndent) {
			elements.append(element)
		}
		return elements
	}
}


// MARK: - Scanner extension


extension NSScanner {

	func passDeclarationIndent(expected: Int) -> Bool {
		var indent = 0
		let saveLocation = scanLocation
		if pass("\t", passWhitespaces: false) {
			indent += 1
			while pass("\t", passWhitespaces: false) {
				indent += 1
			}
		}
		else if pass("    ", passWhitespaces: false) {
			indent += 1
			while pass("    ", passWhitespaces: false) {
				indent += 1
			}
		}
		if indent != expected {
			scanLocation = saveLocation
		}
		return indent == expected
	}


	func parseDeclarationAttributes(elementIndent: Int) throws -> [DeclarationAttribute] {
		var attributes = [DeclarationAttribute]()
		while !atEnd {
			if scanCharactersFromSet(NSCharacterSet.newlineCharacterSet(), intoString: nil) {
				let saveLocation = scanLocation
				if !(passDeclarationIndent(elementIndent + 1) && pass("~", passWhitespaces: true)) {
					scanLocation = saveLocation
					break
				}
			}
			if pass("#", passWhitespaces: true) {
				attributes.append(DeclarationAttribute(name: "id", value: .Value(try expectIdentifier(passWhitespaces: true))))
			}
			else {
				let name = (try expectName(passWhitespaces: true)).lowercaseString
				var value = DeclarationValue.Missing
				if pass("=", passWhitespaces: true) {
					value = try passAttributeValue()
				}
				attributes.append(DeclarationAttribute(name: name, value: value))
			}
		}
		return attributes
	}


	func passAttributeValue() throws -> DeclarationValue {
		if pass("(", passWhitespaces: true) {
			var values = [DeclarationValue]()
			while !pass(")", passWhitespaces: true) {
				let value = try passAttributeValue()
				if value.isMissing {
					throw DeclarationError(message: "Invalid value list", scanner: self)
				}
				values.append(value)
			}
			return .List(values)
		}
		if pass("'", passWhitespaces: false) {
			let value = passUntil("'") ?? ""
			try expect("'", passWhitespaces: true)
			return .Value(value)
		}
		if let value = passUntilEndOrOneOf(valueTerminator, passWhitespaces: true) {
			return .Value(value)
		}
		return .Missing
	}


	func passName(passWhitespaces passWhitespaces: Bool) -> String? {
		var name: NSString?
		guard scanCharactersFromSet(nameCharachters, intoString: &name) else {
			return nil
		}
		if passWhitespaces {
			self.passWhitespaces()
		}
		return String(name!)
	}


	func expectName(passWhitespaces passWhitespaces: Bool) throws -> String {
		guard let passed = passName(passWhitespaces: passWhitespaces) else {
			throw DeclarationError(message: "name expected", scanner: self)
		}
		return passed
	}




}

private let valueTerminator = NSCharacterSet.union(NSCharacterSet.whitespaceAndNewlineCharacterSet(), NSCharacterSet(charactersInString: ")"))
private let nameCharachters = NSCharacterSet.union(NSCharacterSet.alphanumericCharacterSet(), NSCharacterSet(charactersInString: "-."))
