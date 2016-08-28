//
// Created by Michael Vlasov on 16.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit





public enum DeclarationErrorSource {
	case message(String, DeclarationContext)
	case parser(ParseError, DeclarationContext)
	case element(String, DeclarationElement, DeclarationContext)
	case attribute(String, DeclarationAttribute, DeclarationContext)
}





public struct DeclarationError: ErrorType, CustomStringConvertible {
	let source: DeclarationErrorSource

	init(_ message: String, _ attribute: DeclarationAttribute, _ context: DeclarationContext) {
		source = .attribute(message, attribute, context)
	}

	init(_ message: String, _ element: DeclarationElement, _ context: DeclarationContext) {
		source = .element(message, element, context)
	}

	init(_ message: String, _ context: DeclarationContext) {
		source = .message(message, context)
	}

	init(_ parseError: ParseError, _ context: DeclarationContext) {
		source = .parser(parseError, context)
	}

	// MARK: - CustomStringConvertible

	public var description: String {
		switch source {
			case .message(let message, let context):
				return "\(message) in \(context.source)"
			case .parser(let parseError, let context):
				return "\(parseError) in \(context.source)"
			case .element(let message, let element, let context):
				return "\(message) in element [\(element.name)] in \(context.source)"
			case .attribute(let message, let attribute, let context):
				return "\(message) in attribute [\(attribute)] in [\(context.source)]"
		}
	}

}





public class DeclarationContext {

	public var source: String
	public var bindings = DynamicBindings()
	public var hasBindings = false

	init(_ source: String) {
		self.source = source
	}


	public func getFloat(attribute: DeclarationAttribute, _ value: DeclarationValue) throws -> CGFloat {
		switch value {
			case .value(let string):
				return try parseFloat(string, attribute: attribute)
			default:
				throw DeclarationError("Number value expected", attribute, self)
		}
	}


	public func getFloat(attribute: DeclarationAttribute) throws -> CGFloat {
		return try getFloat(attribute, attribute.value)
	}


	public func getEnum<Enum>(attribute: DeclarationAttribute, _ valuesByLowercaseName: [String:Enum]) throws -> Enum {
		switch attribute.value {
			case .value(let value):
				if let resolved = valuesByLowercaseName[value.lowercaseString] {
					return resolved
				}
				throw DeclarationError("Invalid value", attribute, self)
			default:
				throw DeclarationError("Missing required value", attribute, self)
		}
	}


	public func getString(attribute: DeclarationAttribute, _ value: DeclarationValue) throws -> String {
		switch value {
			case .value(let string):
				return string
			default:
				throw DeclarationError("String value expected", attribute, self)
		}
	}


	public func getString(attribute: DeclarationAttribute) throws -> String {
		return try getString(attribute, attribute.value)
	}


	public func getExpression(attribute: DeclarationAttribute, _ value: DeclarationValue) throws -> DynamicBindings.Expression? {
		switch value {
			case .value(let string):
				hasBindings = true
				return bindings.parse(string)
			default:
				throw DeclarationError("String value expected", attribute, self)
		}
	}


	public func getExpression(attribute: DeclarationAttribute) throws -> DynamicBindings.Expression? {
		return try getExpression(attribute, attribute.value)
	}


	public func getImage(attribute: DeclarationAttribute) throws -> UIImage {
		return try getImage(attribute, value: attribute.value)
	}


	public func getImage(attribute: DeclarationAttribute, value: DeclarationValue) throws -> UIImage {
		switch value {
			case .value(let string):
				let nameParts = string.componentsSeparatedByString(".")
				var image: UIImage!
				if nameParts.count < 2 {
					image = UIImage(named: string)
				}
				else {
					let moduleName = nameParts[0]
					let imageName = nameParts[1]
					let bundle = NSBundle.fromModuleName(moduleName)
					image = UIImage(named: imageName, inBundle: bundle, compatibleWithTraitCollection: nil)
				}
				if image != nil {
					return image
				}
				throw DeclarationError("Missing required image", attribute, self)
			default:
				throw DeclarationError("Image name expected", attribute, self)
		}
	}


	public func getBool(attribute: DeclarationAttribute) throws -> Bool {
		switch attribute.value {
			case .value(let string):
				if "true".caseInsensitiveCompare(string) == NSComparisonResult.OrderedSame {
					return true
				}
				if "false".caseInsensitiveCompare(string) == NSComparisonResult.OrderedSame {
					return false
				}
				throw DeclarationError("Boolean value expected (\"true\" or \"false\")", attribute, self)
			case .missing:
				return true
			default:
				throw DeclarationError("Boolean value expected (\"true\" or \"false\")", attribute, self)
		}
	}


	public func getSize(attribute: DeclarationAttribute) throws -> CGSize {
		switch attribute.value {
			case .value(let string):
				let size = try parseFloat(string, attribute: attribute)
				return CGSizeMake(size, size)
			case .list(let values):
				if values.count == 2 {
					return CGSizeMake(try getFloat(attribute, values[0]), try getFloat(attribute, values[1]))
				}
				throw DeclarationError("Size value must contains single number or two numbers (width, height)", attribute, self)
			default:
				throw DeclarationError("Missing size value", attribute, self)
		}
	}


	public func getInsets(attribute: DeclarationAttribute) throws -> UIEdgeInsets {
		switch attribute.value {
			case .value(let string):
				let inset = try parseFloat(string, attribute: attribute)
				return UIEdgeInsetsMake(inset, inset, inset, inset)
			case .list(let values):
				switch values.count {
					case 2:
						let x = try getFloat(attribute, values[0])
						let y = try getFloat(attribute, values[1])
						return UIEdgeInsetsMake(y, x, y, x)
					case 4:
						return UIEdgeInsetsMake(try getFloat(attribute, values[0]), try getFloat(attribute, values[1]), try getFloat(attribute, values[2]), try getFloat(attribute, values[3]))
					default:
						throw DeclarationError("Inset values must contains single number or two numbers (horizontal, vertical) or four numbers (top, left, bottom, right)", attribute, self)
				}
			default:
				throw DeclarationError("Missing insets value", attribute, self)
		}
	}


	public final func applyInsets(inout insets: UIEdgeInsets, name: String, attribute: DeclarationAttribute) throws -> Bool {
		if attribute.name == name {
			insets = try getInsets(attribute)
		}
		else if attribute.name == "\(name)-top" {
			insets.top = try getFloat(attribute)
		}
		else if attribute.name == "\(name)-bottom" {
			insets.bottom = try getFloat(attribute)
		}
		else if attribute.name == "\(name)-left" {
			insets.left = try getFloat(attribute)
		}
		else if attribute.name == "\(name)-right" {
			insets.right = try getFloat(attribute)
		}
		else {
			return false
		}
		return true
	}



	public func getColor(attribute: DeclarationAttribute) throws -> UIColor {
		switch attribute.value {
			case .value(let string):
				return UIColor.parse(string)
			default:
				throw DeclarationError("Missing color value", attribute, self)
		}
	}


	public final func getFont(attribute: DeclarationAttribute, defaultFont: UIFont?) throws -> UIFont {
		return try getFont(attribute, value: attribute.value, defaultFont: defaultFont ?? UIFont.systemFontOfSize(UIFont.systemFontSize()))
	}


	// MARK: - Internals


	public final func getFont(attribute: DeclarationAttribute, value: DeclarationValue, defaultFont: UIFont) throws -> UIFont {
		switch value {
			case .value(let string):
				var size: Float = 0
				if string == "bold" {
					return UIFont(descriptor: defaultFont.fontDescriptor().fontDescriptorWithSymbolicTraits(UIFontDescriptorSymbolicTraits.TraitBold), size: defaultFont.pointSize)
				}
				else if NSScanner(string: string).scanFloat(&size) {
					return defaultFont.fontWithSize(CGFloat(size))
				}
				else {
					return UIFont(name: string, size: defaultFont.pointSize) ?? defaultFont
				}
			case .list(let values):
				var font = defaultFont
				for value in values {
					font = try getFont(attribute, value: value, defaultFont: font)
				}
				return font
			default:
				throw DeclarationError("Font attributes expected", attribute, self)
		}
	}


	private func parseFloat(string: String, attribute: DeclarationAttribute) throws -> CGFloat {
		var value: Float = 0
		if NSScanner(string: string).scanFloat(&value) {
			return CGFloat(value)
		}
		throw DeclarationError("Number expected", attribute, self)
	}


}





public enum DeclarationValue: CustomStringConvertible {
	case missing
	case value(String)
	case list([DeclarationValue])

	public var isMissing: Bool {
		switch self {
			case .missing: return true
			default: return false
		}
	}


	// MARK: - CustomStringConvertible


	public var description: String {
		switch self {
			case .missing:
				return ""
			case .value(let value):
				return "'\(value)'"
			case .list(let values):
				var string = "("
				var isFirst = false
				for value in values {
					if isFirst {
						isFirst = false
					}
					else {
						string += ", "
					}
					string += value.description
				}
				string += ")"
				return string
		}
	}

}
