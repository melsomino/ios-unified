//
// Created by Michael Vlasov on 15.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit




struct LayoutMarkupError: ErrorType {
	let message: String
	init(_ message: String) {
		self.message = message
	}
}





public enum MarkupValue {
	case Missing
	case Text(String)
	case Number(CGFloat)
	case Boolean(Bool)
	case List([MarkupValue])

	public var missing: Bool {
		switch self {
			case .Missing: return true
			default: return false
		}
	}

	public func getEnum<Enum>(valuesByName: [String:Enum]) throws -> Enum {
		switch self {
			case Text(let value):
				return valuesByName[value.lowercaseString]!
			default:
				throw LayoutMarkupError("Invalid value")
		}
	}


	public func getFloat() throws -> CGFloat {
		switch self {
			case Number(let value):
				return value
			default:
				throw LayoutMarkupError("Invalid value")
		}
	}


	public func getBool() throws -> Bool {
		switch self {
			case Boolean(let value):
				return value
			case Missing:
				return true
			default:
				throw LayoutMarkupError("Invalid value")
		}
	}


	public func getSize() throws -> CGSize {
		switch self {
			case Number(let value):
				return CGSizeMake(value, value)
			case List(let values):
				return CGSizeMake(try values[0].getFloat(), try values[1].getFloat())
			default:
				throw LayoutMarkupError("Invalid value")
		}
	}

	public func getInsets() throws -> UIEdgeInsets {
		switch self {
			case Number(let value):
				return UIEdgeInsetsMake(value, value, value, value)
			case List(let values):
				switch values.count {
					case 2:
						let x = try values[0].getFloat()
						let y = try values[1].getFloat()
						return UIEdgeInsetsMake(y, x, y, x)
					case 4:
						return UIEdgeInsetsMake(try values[0].getFloat(), try values[1].getFloat(), try values[2].getFloat(), try values[3].getFloat())
					default:
						throw LayoutMarkupError("Invalid value")
				}
			default:
				throw LayoutMarkupError("Invalid value")
		}
	}


}





public typealias MarkupAttribute = (name:String, value:MarkupValue)





public struct MarkupToken {
	public let attributes: [MarkupAttribute]
	public let children: [MarkupToken]


	public static func parse(source: [String]) throws -> MarkupToken {
		var sourceIndex = 0
		let tokens = try parseChildren(source, childrenIndent: 0, sourceIndex: &sourceIndex)
		guard tokens.count == 1 else {
			throw LayoutMarkupError("Layout markup must define single root element")
		}
		return tokens[0]
	}


	public func createLayoutItem() throws -> LayoutItem {
		let type = attributes[0].name
		switch type {
			case "vertical": return try createLayoutStack(.Vertical)
			case "horizontal": return try createLayoutStack(.Horizontal)
			default:
				throw LayoutMarkupError("Unknown markup element \"\(type)\"")
		}
	}

	private static let alignments = [
		"fill": LayoutAlignment.Fill,
		"leading": LayoutAlignment.Leading,
		"tailing": LayoutAlignment.Tailing,
		"center": LayoutAlignment.Center
	]

	public func createLayoutStack(direction: LayoutStackDirection) throws -> LayoutItem {
		var along = LayoutAlignment.Fill
		var across = LayoutAlignment.Leading
		var spacing = CGFloat(0)
		var content = [LayoutItem]()
		for i in (attributes.count - 1).stride(to: 1, by: -1) {
			let (name, value) = attributes[i]
			switch name.lowercaseString {
				case "along":
					along = try value.getEnum(MarkupToken.alignments)
				case "across":
					across = try value.getEnum(MarkupToken.alignments)
				case "spacing":
					spacing = try value.getFloat()
				default: break
			}
		}

		for child in children {
			try content.append(child.createLayoutItem())
		}
		return LayoutStack(direction: direction, along: along, across: across, spacing: spacing, content)
	}

	// MARK: - Internals


	static func parse(source: [String], expectedIndent: Int, inout sourceIndex: Int) throws -> MarkupToken? {
		guard sourceIndex < source.count else {
			return nil
		}

		let parser = Parser(source: source[sourceIndex], whitespaces: .NotPass)
		guard passIndent(expectedIndent, inParser: parser) else {
			return nil
		}

		let attributes = try parseAttributes(parser)
		sourceIndex += 1
		let children = try parseChildren(source, childrenIndent: expectedIndent + 1, sourceIndex: &sourceIndex)

		return MarkupToken(attributes: attributes, children: children)
	}


	static func passIndent(expected: Int, inParser parser: Parser) -> Bool {
		var indent = 0
		if parser.pass("\t") {
			indent += 1
			while parser.pass("\t") {
				indent += 1
			}
		}
		else if parser.pass("    ") {
			indent += 1
			while parser.pass("    ") {
				indent += 1
			}
		}
		return indent == expected
	}


	static func parseAttributes(parser: Parser) throws -> [MarkupAttribute] {
		var attributes = [MarkupAttribute]()
		while !parser.atEnd {
			let name = try expectAttributeName(parser)
			var value = MarkupValue.Missing
			if parser.pass("=", whitespaces: .Pass) {
				value = try passAttributeValue(parser)
			}
			attributes.append((name, value))
		}
		return attributes
	}


	static func expectAttributeName(parser: Parser) throws -> String {
		if parser.pass("#") {
			return "id"
		}
		return try parser.expectIdentifier(whitespaces: .Pass)
	}


	static func passAttributeValue(parser: Parser) throws -> MarkupValue {
		if let value = parser.passFloat(whitespaces: .Pass) {
			return .Number(value)
		}
		if parser.pass("(", whitespaces: .Pass) {
			var values = [MarkupValue]()
			while !parser.pass(")", whitespaces: .Pass) {
				let value = try passAttributeValue(parser)
				if value.missing {
					throw LayoutMarkupError("Invalid value list")
				}
				values.append(value)
			}
			return .List(values)
		}
		if parser.pass("true", whitespaces: .Pass) {
			return .Boolean(true)
		}
		if parser.pass("false", whitespaces: .Pass) {
			return .Boolean(false)
		}
		if parser.pass("'", whitespaces: .NotPass) {
			let value = parser.passUntil("'") ?? ""
			try parser.expect("'", whitespaces: .Pass)
			return .Text(value)
		}
		if let value = parser.passUntilWhitespaceOrEnd(whitespaces: .Pass) {
			return .Text(value)
		}
		return .Missing
	}


	static func parseChildren(source: [String], childrenIndent: Int, inout sourceIndex: Int) throws -> [MarkupToken] {
		var children = [MarkupToken]()
		while let child = try parse(source, expectedIndent: childrenIndent, sourceIndex: &sourceIndex) {
			children.append(child)
		}
		return children
	}


}





class LayoutMarkup {


}





enum Whitespaces {
	case NotPass, Pass
}





struct Parser {

	init(source: String, whitespaces: Whitespaces = .NotPass) {
		scanner = NSScanner(string: source)
		scanner.charactersToBeSkipped = nil
		self.defaultWhitespaces = whitespaces
		if whitespaces == .Pass {
			passWhitespaces()
		}
	}

	var atEnd: Bool {
		return scanner.atEnd
	}

	func passWhitespaces() {
		scanner.scanCharactersFromSet(Parser.whitespaces, intoString: nil)
	}


	private func passWhitespaces(whitespaces: Whitespaces?) {
		let whitespaces = whitespaces ?? defaultWhitespaces
		if whitespaces == .Pass {
			passWhitespaces()
		}
	}


	func pass(expected: String, whitespaces: Whitespaces? = nil) -> Bool {
		let passed = scanner.scanString(expected, intoString: nil)
		if passed {
			passWhitespaces(whitespaces)
		}
		return passed
	}


	func expect(expected: String, whitespaces: Whitespaces? = nil) throws {
		if !pass(expected, whitespaces: whitespaces) {
			throw LayoutMarkupError("\(expected) expected")
		}
	}


	func passIdentifier(whitespaces whitespaces: Whitespaces? = nil) -> String? {
		var start: NSString?
		guard scanner.scanCharactersFromSet(Parser.identifierStart, intoString: &start) else {
			return nil
		}
		var identifier = String(start!)
		var rest: NSString?
		if scanner.scanCharactersFromSet(Parser.identifierRest, intoString: &rest) {
			identifier += String(rest!)
		}
		passWhitespaces(whitespaces)
		return identifier
	}


	func expectIdentifier(whitespaces whitespaces: Whitespaces? = nil) throws -> String {
		guard let passed = passIdentifier(whitespaces: whitespaces) else {
			throw LayoutMarkupError("identifier expected")
		}
		return passed
	}


	func passFloat(whitespaces whitespaces: Whitespaces? = nil) -> CGFloat? {
		var value: Float = 0
		guard scanner.scanFloat(&value) else {
			return nil
		}
		passWhitespaces(whitespaces)
		return CGFloat(value)
	}


	func passUntil(terminator: String) -> String? {
		var value: NSString?
		return scanner.scanUpToString(terminator, intoString: &value) ? String(value!) : nil
	}


	func passUntilWhitespaceOrEnd(whitespaces whitespaces: Whitespaces? = nil) -> String? {
		var value: NSString?
		if scanner.scanUpToCharactersFromSet(Parser.whitespaces, intoString: &value) {
			passWhitespaces(whitespaces)
			return String(value!)
		}
		return nil
	}


	func expectUntil(terminator: String) throws -> String {
		guard let passed = passUntil(terminator) else {
			throw LayoutMarkupError("can not find terminator \"\(terminator)\"")
		}
		return passed
	}

	private let defaultWhitespaces: Whitespaces
	private var scanner: NSScanner

	private static let whitespaces = NSCharacterSet.whitespaceAndNewlineCharacterSet()
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





