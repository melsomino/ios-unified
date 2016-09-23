//
// Created by Michael Vlasov on 29.06.16.
// Copyright (c) 2016 melsomino. All rights reserved.
//

import Foundation





public struct DynamicBindings {

	public init() {

	}



	public mutating func clear() {
		valueIndexByName.removeAll()
	}



	public mutating func parse(string: String?) -> Expression? {
		let expression = parseString(string)
		return expression
	}



	public static func registerFormatter(name: String, formatterFactory: (String?) -> NSFormatter) {
		formatterFactoryByName[name] = formatterFactory
	}


	// MARK: - Internals


	public var valueIndexByName = [String: Int]()

	private static let openingBrace = "{"
	private static let closingBrace = "}"

	class HtmlToTextFormatter: NSFormatter {
		static let defaultFormatter = HtmlToTextFormatter()
		override func stringForObjectValue(obj: AnyObject) -> String? {
			return HtmlParser.parse(String(obj))
		}
	}

	private static var formatterFactoryByName: [String:(String?) -> NSFormatter] = [
		"date": {
			args in
			let formatter = NSDateFormatter()
			if let args = args {
				formatter.dateFormat = args
			}
			return formatter
		},
		"html-to-text": {
			args in
			return HtmlToTextFormatter.defaultFormatter
		}
	]

	private mutating func parseString(string: String?) -> Expression? {
		let (literal, nonLiteral) = DynamicBindings.split(string, DynamicBindings.openingBrace)
		let (expression, rest) = DynamicBindings.split(nonLiteral, DynamicBindings.closingBrace)
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
		guard let factory = DynamicBindings.formatterFactoryByName[formatterName!] else {
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



		public final func evaluate(values: [Any?]) -> String? {
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



		public final func evaluateBool(values: [Any?]) -> Bool {
			// not {a}
			if let a = Expression.tryGetRightOperand(self, "!") {
				return !Expression.stringToBool(a.evaluateOwnValue(values))
			}

			// {a} == {b}
			if let b = Expression.tryGetRightOperand(next, "==") {
				return Expression.sameOwnValues(self, b, values: values)
			}

			// {a} == {b}
			if let b = Expression.tryGetRightOperand(next, "!=") {
				return !Expression.sameOwnValues(self, b, values: values)
			}

			return Expression.stringToBool(evaluate(values))
		}



		func evaluateOwnValue(values: [Any?]) -> String? {
			return nil
		}


		// MARK: - Internals


		// false if nil OR empty OR false OR 0
		private static func stringToBool(string: String?) -> Bool {
			guard let string = string where !string.isEmpty else {
				return false
			}
			return string != "false" && string != "0"
		}



		private static func isEmpty(string: String?) -> Bool {
			return string == nil || string!.isEmpty
		}



		private static func tryGetRightOperand(operation: Expression?, _ op: String) -> Expression? {
			guard let operation = operation as? Literal else {
				return nil
			}
			let operationName = operation.value.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
			if let right = operation.next {
				return (operationName == op && right.next == nil) ? right : nil
			}
			guard operationName.hasPrefix(op) else {
				return nil
			}
			let right = operationName.substringFromIndex(operationName.startIndex.advancedBy(op.characters.count))
			return Literal(value: right.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()), next: nil)
		}



		private static func sameOwnValues(a: Expression, _ b: Expression, values: [Any?]) -> Bool {
			let aValue = a.evaluateOwnValue(values)
			let bValue = b.evaluateOwnValue(values)
			let aEmpty = isEmpty(aValue)
			let bEmpty = isEmpty(bValue)
			if aEmpty && bEmpty {
				return true
			}
			if aEmpty || bEmpty {
				return false
			}
			return aValue! == bValue!
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
				case let v as Uuid:
					return String.fromUuid(v)
				case let v as Int:
					return String(v)
				case let v as Float:
					return String(v)
				case let string as String:
					if let formatter = formatter {
						return formatter.stringForObjectValue(string)
					}
					return string
				case let date as NSDate:
					if let formatter = formatter {
						return formatter.stringForObjectValue(date)
					}
					return String(date)
				default:
					let s = String(value)
					if s == "nil" {
						return nil
					}
					if let formatter = formatter {
						return formatter.stringForObjectValue(s)
					}
					return s
			}
		}
	}

}
