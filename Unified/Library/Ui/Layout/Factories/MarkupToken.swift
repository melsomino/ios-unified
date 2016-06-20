//
// Created by Власов М.Ю. on 16.06.16.
// Copyright (c) 2016 melsomino. All rights reserved.
//

import Foundation
import UIKit


public typealias MarkupAttribute = (name:String, value:MarkupValue)





public struct MarkupToken {
	public let name: String
	public let attributes: [MarkupAttribute]
	public let children: [MarkupToken]


	public static func parse(source: String) throws -> MarkupToken {
		var sourceIndex = 0
		let tokens = try parseChildren(source, childrenIndent: 0, sourceIndex: &sourceIndex)
		guard tokens.count == 1 else {
			throw LayoutMarkupError("Layout markup must define single root element")
		}
		return tokens[0]
	}


	public static func parse(source: [String]) throws -> MarkupToken {
		var sourceIndex = 0
		let tokens = try parseChildren(source, childrenIndent: 0, sourceIndex: &sourceIndex)
		guard tokens.count == 1 else {
			throw LayoutMarkupError("Layout markup must define single root element")
		}
		return tokens[0]
	}


	// MARK: - Internals

	static func parse(source: [String], expectedIndent: Int, inout sourceIndex: Int) throws -> MarkupToken? {
		guard sourceIndex < source.count else {
			return nil
		}

		let scanner = NSScanner(source: source[sourceIndex], passWhitespaces: false)
		guard scanner.passMarkupIndent(expectedIndent) else {
			return nil
		}

		let name = (try scanner.expectIdentifier(passWhitespaces: true)).lowercaseString
		let attributes = try scanner.parseMarkupAttributes()
		sourceIndex += 1
		let children = try parseChildren(source, childrenIndent: expectedIndent + 1, sourceIndex: &sourceIndex)

		return MarkupToken(name: name, attributes: attributes, children: children)
	}


	static func parseChildren(source: [String], childrenIndent: Int, inout sourceIndex: Int) throws -> [MarkupToken] {
		var children = [MarkupToken]()
		while let child = try parse(source, expectedIndent: childrenIndent, sourceIndex: &sourceIndex) {
			children.append(child)
		}
		return children
	}


}


// MARK: - Scanner extension


extension NSScanner {

	func passMarkupIndent(expected: Int) -> Bool {
		var indent = 0
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
		return indent == expected
	}


	func parseMarkupAttributes() throws -> [MarkupAttribute] {
		var attributes = [MarkupAttribute]()
		while !atEnd {
			if pass("#", passWhitespaces: true) {
				attributes.append(("id", .Value(try expectIdentifier(passWhitespaces: true))))
			}
			else {
				let name = (try expectIdentifier(passWhitespaces: true)).lowercaseString
				var value = MarkupValue.Missing
				if pass("=", passWhitespaces: true) {
					value = try passAttributeValue()
				}
				attributes.append((name, value))
			}
		}
		return attributes
	}


	func passAttributeValue() throws -> MarkupValue {
		if pass("(", passWhitespaces: true) {
			var values = [MarkupValue]()
			while !pass(")", passWhitespaces: true) {
				let value = try passAttributeValue()
				if value.missing {
					throw LayoutMarkupError("Invalid value list")
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




}

private let valueTerminator = NSCharacterSet.union(NSCharacterSet.whitespaceAndNewlineCharacterSet(), NSCharacterSet(charactersInString: ")"))
