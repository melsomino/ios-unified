//
// Created by Michael Vlasov on 29.06.16.
// Copyright (c) 2016 melsomino. All rights reserved.
//

import Foundation





public struct UiBinding {

	public init() {

	}


	private static let opening_brace = "{"
	private static let closing_brace = "}"


	public mutating func parse(string: String?) -> Expression? {
		let (literal, non_literal) = UiBinding.split(string, UiBinding.opening_brace)
		let (expression, rest) = UiBinding.split(non_literal, UiBinding.closing_brace)
		if literal != nil && expression != nil && rest != nil {
			return parse_literal(literal!, parse_expression(expression!, parse(rest)))
		}
		if literal != nil && expression != nil {
			return parse_literal(literal!, parse_expression(expression!, nil))
		}
		if expression != nil && rest != nil {
			return parse_expression(expression!, parse(rest))
		}
		if expression != nil {
			return parse_expression(expression!, nil)
		}
		return nil
	}


	private func parse_literal(string: String, _ next: Expression?) -> Expression {
		return Literal(value: string, next: next)
	}


	private mutating func parse_expression(string: String, _ next: Expression?) -> Expression {
		let name = string
		var value_index = value_index_by_name[name]
		if value_index == nil {
			value_index = values.count
			values.append(nil)
			value_index_by_name[name] = value_index!
		}
		return Value(value_index: value_index!, next: next)
	}


	private static func split(string: String?, _ separator: String) -> (String?, String?) {
		guard let string = string else {
			return (nil, nil)
		}
		guard !string.isEmpty else {
			return (nil, nil)
		}
		guard let separator_range = string.rangeOfString(separator, options: .LiteralSearch, range: string.startIndex ..< string.endIndex) else {
			return (string, nil)
		}
		let left = substring(string, string.startIndex, separator_range.startIndex)
		let right = substring(string, separator_range.endIndex, string.endIndex)
		return (left, right)
	}


	private static func substring(string: String?, _ start: String.Index, _ end: String.Index) -> String? {
		return string != nil && start != end ? string!.substringWithRange(start ..< end) : nil
	}

	public mutating func setModel(model: Any?) {
		guard values.count > 0 else {
			return
		}
		for i in 0 ..< values.count {
			values[i] = nil
		}
		if model != nil {
			let mirror = Mirror(reflecting: model!)
			for member in mirror.children {
				if let name = member.label {
					if let index = value_index_by_name[name] {
						values[index] = member.value
					}
				}
			}
		}
	}


	public func evaluateExpression(expression: Expression?) -> String? {
		var expression = expression
		var result: String?
		while expression != nil {
			let value = expression!.evaluate(values)
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


	// MARK: - Internals

	private var value_index_by_name = [String: Int]()
	private var values = [Any?]()





	public class Expression {
		let next: Expression?

		init(next: Expression?) {
			self.next = next
		}


		func evaluate(values: [Any?]) -> String? {
			return nil
		}
	}





	class Literal: Expression {
		let value: String

		init(value: String, next: Expression?) {
			self.value = value
			super.init(next: next)
		}


		override func evaluate(values: [Any?]) -> String? {
			return value
		}
	}





	class Value: Expression {
		let value_index: Int

		init(value_index: Int, next: Expression?) {
			self.value_index = value_index
			super.init(next: next)
		}


		override func evaluate(values: [Any?]) -> String? {
			guard let value = values[value_index] else {
				return nil
			}
			return String(value)
		}
	}

}
