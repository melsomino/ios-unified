//
// Created by Власов М.Ю. on 16.06.16.
// Copyright (c) 2016 melsomino. All rights reserved.
//

import Foundation
import UIKit





public struct DeclarationAttribute {
	public let name: String
	public let value: DeclarationValue


}





public struct DeclarationElement {
	public let attributes: [DeclarationAttribute]
	public let children: [DeclarationElement]


	public var name: String {
		return attributes[0].name
	}


	public var value: String? {
		return attributes.count > 1 ? attributes[1].name : nil
	}

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

		scanner.passEmptyAndCommentLines()

		guard scanner.passDeclarationIndent(elementIndent) else {
			return nil
		}

		let attributes = try scanner.parseDeclarationAttributes(elementIndent)
		let children = try parseElements(scanner, elementIndent: elementIndent + 1)

		return DeclarationElement(attributes: attributes, children: children)
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

	func passEmptyAndCommentLines() {
		while !atEnd {
			let saveLocation = scanLocation
			passWhitespaces()
			if pass("#", passWhitespaces: false) {
				passUntilEndOrOneOf(NSCharacterSet.newlineCharacterSet(), passWhitespaces: false)
			}
			if atEnd {
				return
			}
			if passCharacters(NSCharacterSet.newlineCharacterSet(), passWhitespaces: false) == nil {
				scanLocation = saveLocation
				return
			}
		}
	}


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
			if passCharacters(NSCharacterSet.newlineCharacterSet()) != nil {
				let saveLocation = scanLocation
				if !(passDeclarationIndent(elementIndent + 1) && pass("~", passWhitespaces: true)) {
					scanLocation = saveLocation
					break
				}
			}
			let name = try expectName(passWhitespaces: true)
			var value = DeclarationValue.Missing
			if pass("=", passWhitespaces: true) {
				value = try passAttributeValue()
			}
			attributes.append(DeclarationAttribute(name: name, value: value))
		}
		return attributes
	}


	func passAttributeValue() throws -> DeclarationValue {
		if pass("(", passWhitespaces: true) {
			var values = [DeclarationValue]()
			while !pass(")", passWhitespaces: true) {
				guard let value = try passNameOrValue() else {
					throw DeclarationError(message: "Invalid value list", scanner: self)
				}
				values.append(.Value(value))
			}
			return .List(values)
		}
		return try .Value(passNameOrValue()!)
	}


	func passNameOrValue() throws -> String? {
		if pass("'", passWhitespaces: false) {
			let value = passUntil("'")
			try expect("'", passWhitespaces: true)
			return value
		}
		if pass("\"", passWhitespaces: false) {
			let value = passUntil("\"")
			try expect("\"", passWhitespaces: true)
			return value
		}
		return passUntilEndOrOneOf(nameOrValueTerminator, passWhitespaces: true)
	}


	func expectName(passWhitespaces passWhitespaces: Bool) throws -> String {
		guard let passed = try passNameOrValue() else {
			throw DeclarationError(message: "name expected", scanner: self)
		}
		if passWhitespaces {
			self.passWhitespaces()
		}
		return passed
	}


}





private let nameOrValueTerminator = NSCharacterSet.union(NSCharacterSet.whitespaceAndNewlineCharacterSet(), NSCharacterSet(charactersInString: "=()'~"))
private let nameCharacters = NSCharacterSet.union(NSCharacterSet.alphanumericCharacterSet(), NSCharacterSet(charactersInString: "-."))
