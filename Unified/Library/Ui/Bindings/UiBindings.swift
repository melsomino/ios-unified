//
// Created by Michael Vlasov on 29.06.16.
// Copyright (c) 2016 melsomino. All rights reserved.
//

import Foundation





public struct UiBindings {

	public init() {

	}


	public mutating func parse(string: String?) -> Expression? {
		let expression = parseString(string)
		print("Binding: \(string) parsed to: \(expression)")
		return expression
	}


	public static func registerFormatter(name: String, formatterFactory: (String?) -> NSFormatter) {
		formatterFactoryByName[name] = formatterFactory
	}


	// MARK: - Internals


	public var valueIndexByName = [String: Int]()

	private static let openingBrace = "{"
	private static let closingBrace = "}"

	private static var formatterFactoryByName: [String:(String?) -> NSFormatter] = [
		"date": {
			args in
			let formatter = NSDateFormatter()
			if let args = args {
				formatter.dateFormat = args
			}
			formatter.calendar = NSCalendar.currentCalendar()
			formatter.timeZone = NSCalendar.currentCalendar().timeZone
			return formatter
		}
	]

	private mutating func parseString(string: String?) -> Expression? {
		let (literal, nonLiteral) = UiBindings.split(string, UiBindings.openingBrace)
		let (expression, rest) = UiBindings.split(nonLiteral, UiBindings.closingBrace)
		if literal != nil && expression != nil && rest != nil {
			return Literal(value: literal!, next: parseExpression(expression!, parse(rest)))
		}
		if literal != nil && expression != nil {
			return Literal(value: literal!, next: parseExpression(expression!, nil))
		}
		if expression != nil && rest != nil {
			return parseExpression(expression!, parse(rest))
		}
		if expression != nil {
			return parseExpression(expression!, nil)
		}
		if literal != nil {
			return Literal(value: literal!, next: nil)
		}
		return nil
	}


	private mutating func parseExpression(string: String, _ next: Expression?) -> Expression {
		var name = string
		var formatter: NSFormatter? = nil
		if let formatSeparatorRange = string.rangeOfString(" ") {
			name = string.substringWithRange(string.startIndex ..< formatSeparatorRange.startIndex)
			formatter = parseFormatter(string.substringFromIndex(formatSeparatorRange.endIndex))
		}

		var valueIndex = valueIndexByName[name]
		if valueIndex == nil {
			valueIndex = valueIndexByName.count
			valueIndexByName[name] = valueIndex!
		}

		return Value(value_index: valueIndex!, formatter: formatter, next: next)
	}


	private func parseFormatter(string: String) -> NSFormatter? {
		let scanner = NSScanner(source: string, passWhitespaces: false)
		scanner.passWhitespaces()
		guard let name = try? scanner.passNameOrValue() else {
			return nil
		}
		guard name == "format" else {
			return nil
		}
		guard scanner.pass("=", passWhitespaces: true) else {
			return nil
		}
		guard let formatterName = try? scanner.passNameOrValue() else {
			return nil
		}
		var formatterArgs: String?
		if scanner.pass("(", passWhitespaces: false) {
			formatterArgs = scanner.passUntil(")")
			guard formatterArgs != nil else {
				return nil
			}
			guard scanner.pass(")", passWhitespaces: true) else {
				return nil
			}
		}
		guard let factory = UiBindings.formatterFactoryByName[formatterName!] else {
			return nil
		}
		return factory(formatterArgs)
	}


	private static func split(string: String?, _ separator: String) -> (String?, String?) {
		guard let string = string else {
			return (nil, nil)
		}
		guard !string.isEmpty else {
			return (nil, nil)
		}
		guard let separatorRange = string.rangeOfString(separator, options: .LiteralSearch, range: string.startIndex ..< string.endIndex) else {
			return (string, nil)
		}
		let left = substring(string, string.startIndex, separatorRange.startIndex)
		let right = substring(string, separatorRange.endIndex, string.endIndex)
		return (left, right)
	}


	private static func substring(string: String?, _ start: String.Index, _ end: String.Index) -> String? {
		return string != nil && start != end ? string!.substringWithRange(start ..< end) : nil
	}




	public class Expression {
		let next: Expression?

		init(next: Expression?) {
			self.next = next
		}


		public func evaluate(values: [Any?]) -> String? {
			var expression: Expression? = self
			var result: String?
			while expression != nil {
				let value = expression!.evaluateOwnValue(values)
				if let value = value {
					if result == nil {
						result = value
					}
					else {
						result! += value
					}
				}
				expression = expression!.next
			}
			return result
		}

		func evaluateOwnValue(values: [Any?]) -> String? {
			return nil
		}
	}





	class Literal: Expression {
		let value: String

		init(value: String, next: Expression?) {
			self.value = value
			super.init(next: next)
		}


		override func evaluateOwnValue(values: [Any?]) -> String? {
			return value
		}
	}





	class Value: Expression {
		let valueIndex: Int
		let formatter: NSFormatter?

		init(value_index: Int, formatter: NSFormatter?, next: Expression?) {
			self.valueIndex = value_index
			self.formatter = formatter
			super.init(next: next)
		}


		override func evaluateOwnValue(values: [Any?]) -> String? {
			guard let value = values[valueIndex] else {
				return nil
			}
			switch value {
				case let string as String:
					return string
				case let date as NSDate:
					if let formatter = formatter {
						return formatter.stringForObjectValue(date)
					}
					return String(date)
				default:
					return String(value)
			}
		}
	}

}
