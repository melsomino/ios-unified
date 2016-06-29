//
// Created by Michael Vlasov on 27.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
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


	private static let jsonNumberFormatter: NSNumberFormatter = {
		let formatter = NSNumberFormatter()
		formatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
		formatter.decimalSeparator = "."
		return formatter
	}()





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
		if let array = try passJsonArray() {
			return array
		}
		if let object = try passJsonObject() {
			return object
		}
		if let number = try passJsonNumber() {
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





	private func passJsonArray() throws -> [AnyObject]? {
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





	private func passJsonObject() throws -> [String: AnyObject]? {
		if !pass("{", passWhitespaces: true) {
			return nil
		}
		var object = [String: AnyObject]()
		if !pass("}", passWhitespaces: true) {
			while true {
				guard let name = try passJsonString() else {
					throw JsonError("Object property name expected")
				}
				try expect("=", passWhitespaces: true)
				object[name] = try expectJsonValue()
				if pass("}", passWhitespaces: true) {
					break
				}
				try expect(",", passWhitespaces: true)
			}
		}
		return object
	}





	private func passJsonNumber() throws -> AnyObject? {
		let saveLocation = scanLocation
		pass("-")
		if pass("0") {
		}
		else if passCharacters(NSCharacterSet.decimalDigitCharacterSet()) != nil {
		}
		else {
			scanLocation = saveLocation
			return nil
		}
		if pass(".") {
			try expectCharacters(NSCharacterSet.decimalDigitCharacterSet(), expectedDescription: "Decimal digits")
		}
		if pass("e") || pass("E") {
			if pass("+") || pass("-") {
			}
			try expectCharacters(NSCharacterSet.decimalDigitCharacterSet(), expectedDescription: "Decimal digits")
		}
		if let number = NSScanner.jsonNumberFormatter.numberFromString(substring(saveLocation, scanLocation)) {
			return number
		}
		throw JsonError("Invalid number")
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
				value += String(Int32(strtoul(substring(scanLocation, scanLocation + 4), nil, 16)))
				scanLocation += 4
			}
			else {
				throw JsonError("Invalid escape char in string value")
			}
		}
		return value
	}




	private func substring(start: Int, _ end: Int) -> String {
		let startIndex = string.startIndex.advancedBy(start)
		return string.substringWithRange(startIndex ..< startIndex.advancedBy(end - start))
	}




	private static let backslashOrDoubleQuotationMark = NSCharacterSet(charactersInString: "\"\\")
}
