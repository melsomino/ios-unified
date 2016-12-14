//
// Created by Michael Vlasov on 16.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit



public struct DeclarationAttribute: CustomStringConvertible {
	public var name: String
	public var value: DeclarationValue

	// MARK: - CustomStringConvertible

	public var description: String {
		switch value {
			case .missing:
				return "\(name)"
			default:
				return "'\(name)'=\(value)"
		}
	}

}



public struct DeclarationElement {
	public var attributes: [DeclarationAttribute]
	public var children: [DeclarationElement]


	public var name: String {
		return attributes[0].name
	}


	public var value: String? {
		return attributes.count > 1 ? attributes[1].name : nil
	}

	public static func load(_ path: String) throws -> [DeclarationElement] {
		let string = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
		return try parse(string)
	}



	public func attributes(from start: Int) -> ArraySlice<DeclarationAttribute> {
		return attributes[start ..< attributes.count]
	}

	public var skipName: ArraySlice<DeclarationAttribute> {
		return attributes[1 ..< attributes.count]
	}

	public func find(attribute: String) -> DeclarationAttribute? {
		return attributes.find({ $0.name == attribute })
	}



	public func find(child: String) -> DeclarationElement? {
		return children.find({ $0.name == child })
	}



	public static func parse(_ source: String) throws -> [DeclarationElement] {
		let scanner = Scanner(source: source, passWhitespaces: false)
		return try parseElements(scanner, elementIndent: 0)
	}



	// MARK: - Internals


	static func parseElement(_ scanner: Scanner, elementIndent: Int) throws -> DeclarationElement? {
		guard !scanner.isAtEnd else {
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



	static func parseElements(_ scanner: Scanner, elementIndent: Int) throws -> [DeclarationElement] {
		var elements = [DeclarationElement]()
		while let element = try parseElement(scanner, elementIndent: elementIndent) {
			elements.append(element)
		}
		return elements
	}

}






// MARK: - Scanner extension



extension Scanner {

	func passEmptyAndCommentLines() {
		while !isAtEnd {
			let saveLocation = scanLocation
			passWhitespaces()
			if pass("#", passWhitespaces: false) {
				let _ = passUntilEndOrOneOf(CharacterSet.newlines, passWhitespaces: false)
			}
			if isAtEnd {
				return
			}
			if passCharacters(CharacterSet.newlines, passWhitespaces: false) == nil {
				scanLocation = saveLocation
				return
			}
		}
	}



	func passDeclarationIndent(_ expected: Int) -> Bool {
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



	func parseDeclarationAttributes(_ elementIndent: Int) throws -> [DeclarationAttribute] {
		var attributes = [DeclarationAttribute]()
		while !isAtEnd {
			if passCharacters(CharacterSet.newlines) != nil {
				let saveLocation = scanLocation
				if !(passDeclarationIndent(elementIndent + 1) && pass("~", passWhitespaces: true)) {
					scanLocation = saveLocation
					break
				}
			}
			let name = try expectName(passWhitespaces: true)
			var value = DeclarationValue.missing
			if pass("=", passWhitespaces: true) {
				value = try passAttributeValue()
			}
			attributes.append(DeclarationAttribute(name: name, value: value))
		}
		return attributes
	}



	func passAttributeValue() throws -> DeclarationValue {
		if pass("(", passWhitespaces: true) {
			var values = [String]()
			while !pass(")", passWhitespaces: true) {
				guard let value = try passNameOrValue() else {
					throw ParseError("Invalid value list", self)
				}
				values.append(value)
			}
			return .list(values)
		}
		return try .value(passNameOrValue()!)
	}



	func passNameOrValue() throws -> String? {
		if pass("'", passWhitespaces: false) {
			let value = passUntil("'") ?? ""
			try expect("'", passWhitespaces: true)
			return value
		}
		if pass("\"", passWhitespaces: false) {
			let value = passUntil("\"") ?? ""
			try expect("\"", passWhitespaces: true)
			return value
		}
		return passUntilEndOrOneOf(nameOrValueTerminator, passWhitespaces: true)
	}



	func expectName(passWhitespaces: Bool) throws -> String {
		guard let passed = try passNameOrValue() else {
			throw ParseError("name expected", self)
		}
		if passWhitespaces {
			self.passWhitespaces()
		}
		return passed
	}


}



private let nameOrValueTerminator = CharacterSet.union(CharacterSet.whitespacesAndNewlines, CharacterSet(charactersIn: "=()'~"))
private let nameCharacters = CharacterSet.union(CharacterSet.alphanumerics, CharacterSet(charactersIn: "-."))
