//
// Created by Michael Vlasov on 27.06.16.
// Copyright (c) 2016 melsomino. All rights reserved.
//

import Foundation


public class JsonError: ErrorType {
	public let message: String
	public let cause: ErrorType?

	public init(_ message: String, _ cause: ErrorType? = nil) {
		self.message = message
		self.cause = cause
	}
}


extension NSScanner {

	public static func parseJson(source: String) throws -> AnyObject? {
		let scanner = NSScanner(source: source, passWhitespaces: false)
		scanner.passWhitespaces()
		if scanner.atEnd {
			return nil
		}
		let value = try scanner.expectJsonValue()
		if !scanner.atEnd {
			throw JsonError("Invalid JSON string")
		}
		return value
	}

	private func expectJsonValue() throws-> AnyObject {
		if let string = try passJsonString() {
			return string
		}
		if let array = passJsonArray() {
			return array
		}
		if let object = passJsonObject() {
			return object
		}
		if let number = passJsonNumber() {
			return number
		}
		if pass("true", passWhitespaces: true) {
			return true
		}
		if pass("false", passWhitespaces: true) {
			return false
		}
		if pass("null", passWhitespaces: true) {
			return NSNull()
		}
		throw JsonError("Value expected")
	}

	private func passJsonString() throws -> String? {
		if !pass("\"") {
			return nil
		}
		var value = ""
		while true {
			if let unescapedChars = passUntilEndOrOneOf(NSScanner.backslashOrDoubleQuotationMark, passWhitespaces: false) {
				value += String(unescapedChars)
			}
			if atEnd {
				throw JsonError("Unterminated string")
			}
			if pass("\"", passWhitespaces: true) {
				break
			}
			try expect("\\", passWhitespaces: false)
			if pass("\"") {
				value += "\""
			}
			else if pass("\\") {
				value += "\\"
			}
			else if pass("/") {
				value += "/"
			}
			else if pass("b") {
				value += "\u{08}"
			}
			else if pass("f") {
				value += "\u{0c}"
			}
			else if pass("n") {
				value += "\n"
			}
			else if pass("r") {
				value += "\r"
			}
			else if pass("t") {
				value += "\t"
			}
			else if pass("u") {
				if scanLocation + 4 > string.characters.count {
					throw JsonError("Invalid hex escape ins string value")
				}
				let scanIndex = string.startIndex.advancedBy(scanLocation)
				let uncode = string.substringWithRange(scanIndex ..< scanIndex.advancedBy(4))
				value += String(Int32(strtoul(unicode), nil, 16))
				scanLocation += 4
			}
			else {
				throw JsonError("Invalid escape char in string value")
			}
		}
		return value
	}

	private static let backslashOrDoubleQuotationMark = NSCharacterSet(charactersInString: "\"\\")
}
