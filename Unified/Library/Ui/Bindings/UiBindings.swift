//
// Created by Michael Vlasov on 29.06.16.
// Copyright (c) 2016 melsomino. All rights reserved.
//

import Foundation





public struct UiBindings {

	public init() {

	}


	public mutating func parse(string: String?) -> Expression? {
		guard let expression = parseString(string) else {
			return nil
		}
		if let literal = expression as? Literal {
			if literal.next == nil {
				return nil
			}
		}
		return expression
	}

	// MARK: - Internals

	public var valueIndexByName = [String: Int]()

	private static let openingBrace = "{"
	private static let closingBrace = "}"


	private mutating func parseString(string: String?) -> Expression? {
		let (literal, nonLiteral) = UiBindings.split(string, UiBindings.openingBrace)
		let (expression, rest) = UiBindings.split(nonLiteral, UiBindings.closingBrace)
		if literal != nil && expression != nil && rest != nil {
			return parseLiteral(literal!, parseExpression(expression!, parse(rest)))
		}
		if literal != nil && expression != nil {
			return parseLiteral(literal!, parseExpression(expression!, nil))
		}
		if expression != nil && rest != nil {
			return parseExpression(expression!, parse(rest))
		}
		if expression != nil {
			return parseExpression(expression!, nil)
		}
		return nil
	}


	private func parseLiteral(string: String, _ next: Expression?) -> Expression {
		return Literal(value: string, next: next)
	}


	private mutating func parseExpression(string: String, _ next: Expression?) -> Expression {
		var name = string
		let formatter: NSFormatter? = nil
		if let formatSeparatorRange = string.rangeOfString(" ") {
			name = string.substringWithRange(string.startIndex ..< formatSeparatorRange.startIndex)
		}

		var valueIndex = valueIndexByName[name]
		if valueIndex == nil {
			valueIndex = valueIndexByName.count
			valueIndexByName[name] = valueIndex!
		}

		return Value(value_index: valueIndex!, formatter: formatter, next: next)
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
			if let formatter = formatter, valueObject = value as? AnyObject {
				return formatter.stringForObjectValue(valueObject)
			}
			return String(value)
		}
	}

}
