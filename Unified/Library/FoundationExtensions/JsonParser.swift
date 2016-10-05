//
// Created by Michael Vlasov on 27.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation


open class JsonError: Error {
	open let message: String
	open let cause: Error?

	public init(_ message: String, _ cause: Error? = nil) {
		self.message = message
		self.cause = cause
	}
}





extension Scanner {


	fileprivate static let jsonNumberFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = NumberFormatter.Style.decimal
		formatter.decimalSeparator = "."
		return formatter
	}()





	public static func parseJson(_ source: String) throws -> AnyObject {
		let scanner = Scanner(source: source, passWhitespaces: false)
		scanner.passWhitespaces()
		if scanner.isAtEnd {
			throw JsonError("Empty JSON string")
		}
		let value = try scanner.expectJsonValue()
		if !scanner.isAtEnd {
			throw JsonError("Invalid JSON string")
		}
		return value
	}





	fileprivate func expectJsonValue() throws-> AnyObject {
		if let string = try passJsonString() {
			return string as AnyObject
		}
		if let array = try passJsonArray() {
			return array as AnyObject
		}
		if let object = try passJsonObject() {
			return object as AnyObject
		}
		if let number = try passJsonNumber() {
			return number
		}
		if pass("true", passWhitespaces: true) {
			return true as AnyObject
		}
		if pass("false", passWhitespaces: true) {
			return false as AnyObject
		}
		if pass("null", passWhitespaces: true) {
			return NSNull()
		}
		throw JsonError("Value expected")
	}





	fileprivate func passJsonArray() throws -> [AnyObject]? {
		if !pass("[", passWhitespaces: true) {
			return nil
		}
		var array = [AnyObject]()
		if !pass("]", passWhitespaces: true) {
			while true {
				array.append(try expectJsonValue())
				if pass("]", passWhitespaces: true) {
					break
				}
				try expect(",", passWhitespaces: true)
			}
		}
		return array
	}





	fileprivate func passJsonObject() throws -> [String: AnyObject]? {
		if !pass("{", passWhitespaces: true) {
			return nil
		}
		var object = [String: AnyObject]()
		if !pass("}", passWhitespaces: true) {
			while true {
				guard let name = try passJsonString() else {
					throw JsonError("Object property name expected")
				}
				try expect(":", passWhitespaces: true)
				object[name] = try expectJsonValue()
				if pass("}", passWhitespaces: true) {
					break
				}
				try expect(",", passWhitespaces: true)
			}
		}
		return object
	}





	fileprivate func passJsonNumber() throws -> AnyObject? {
		let saveLocation = scanLocation
		pass("-")
		if pass("0") {
		}
		else if passCharacters(CharacterSet.decimalDigits) != nil {
		}
		else {
			scanLocation = saveLocation
			return nil
		}
		if pass(".") {
			try expectCharacters(CharacterSet.decimalDigits, expectedDescription: "Decimal digits")
		}
		if pass("e") || pass("E") {
			if pass("+") || pass("-") {
			}
			try expectCharacters(CharacterSet.decimalDigits, expectedDescription: "Decimal digits")
		}
		if let number = Scanner.jsonNumberFormatter.number(from: substring(saveLocation, scanLocation)) {
			return number
		}
		throw JsonError("Invalid number")
	}





	fileprivate func passJsonString() throws -> String? {
		if !pass("\"") {
			return nil
		}
		var value = ""
		while true {
			if let unescapedChars = passUntilEndOrOneOf(Scanner.backslashOrDoubleQuotationMark, passWhitespaces: false) {
				value += String(unescapedChars)
			}
			if isAtEnd {
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
				value += String(Int32(strtoul(substring(scanLocation, scanLocation + 4), nil, 16)))
				scanLocation += 4
			}
			else {
				throw JsonError("Invalid escape char in string value")
			}
		}
		return value
	}




	fileprivate func substring(_ start: Int, _ end: Int) -> String {
		let startIndex = string.characters.index(string.startIndex, offsetBy: start)
		return string.substring(with: startIndex ..< startIndex.advancedBy(end - start))
	}




	fileprivate static let backslashOrDoubleQuotationMark = CharacterSet(charactersIn: "\"\\")
}
