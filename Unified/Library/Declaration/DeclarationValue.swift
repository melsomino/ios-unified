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





public struct DeclarationError: Error, CustomStringConvertible {
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





open class DeclarationContext {

	open var source: String
	open var bindings = DynamicBindings()
	open var hasBindings = false

	init(_ source: String) {
		self.source = source
	}



	public final func reset() {
		bindings.clear()
		hasBindings = false
	}



	open func getFloat(_ attribute: DeclarationAttribute, _ value: DeclarationValue) throws -> CGFloat {
		switch value {
			case .value(let string):
				return try parseFloat(string, attribute: attribute)
			default:
				throw DeclarationError("Number value expected", attribute, self)
		}
	}



	open func getFloat(_ attribute: DeclarationAttribute) throws -> CGFloat {
		return try getFloat(attribute, attribute.value)
	}



	open func getEnum<Enum>(_ attribute: DeclarationAttribute, _ valuesByLowercaseName: [String: Enum]) throws -> Enum {
		switch attribute.value {
			case .value(let value):
				if let resolved = valuesByLowercaseName[value.lowercased()] {
					return resolved
				}
				throw DeclarationError("Invalid value", attribute, self)
			default:
				throw DeclarationError("Missing required value", attribute, self)
		}
	}



	open func getString(_ attribute: DeclarationAttribute, _ value: DeclarationValue) throws -> String {
		switch value {
			case .value(let string):
				return string
			default:
				throw DeclarationError("String value expected", attribute, self)
		}
	}



	open func getString(_ attribute: DeclarationAttribute) throws -> String {
		return try getString(attribute, attribute.value)
	}



	open func getExpression(_ attribute: DeclarationAttribute, _ value: DeclarationValue) throws -> DynamicBindings.Expression? {
		switch value {
			case .value(let string):
				hasBindings = true
				return bindings.parse(string)
			default:
				throw DeclarationError("String value expected", attribute, self)
		}
	}



	open func getExpression(_ attribute: DeclarationAttribute) throws -> DynamicBindings.Expression? {
		return try getExpression(attribute, attribute.value)
	}



	open func getImage(_ attribute: DeclarationAttribute) throws -> UIImage {
		return try getImage(attribute, value: attribute.value)
	}



	open func getImage(_ attribute: DeclarationAttribute, value: DeclarationValue) throws -> UIImage {
		switch value {
			case .value(let string):
				let nameParts = string.components(separatedBy: ".")
				var image: UIImage!
				if nameParts.count < 2 {
					image = UIImage(named: string)
				}
				else {
					let moduleName = nameParts[0]
					let imageName = nameParts[1]
					let bundle = Bundle.fromModuleName(moduleName)
					image = UIImage(named: imageName, in: bundle, compatibleWith: nil)
				}
				if image != nil {
					return image
				}
				throw DeclarationError("Missing required image", attribute, self)
			default:
				throw DeclarationError("Image name expected", attribute, self)
		}
	}



	open func getBool(_ attribute: DeclarationAttribute) throws -> Bool {
		switch attribute.value {
			case .value(let string):
				if "true".caseInsensitiveCompare(string) == ComparisonResult.orderedSame {
					return true
				}
				if "false".caseInsensitiveCompare(string) == ComparisonResult.orderedSame {
					return false
				}
				throw DeclarationError("Boolean value expected (\"true\" or \"false\")", attribute, self)
			case .missing:
				return true
			default:
				throw DeclarationError("Boolean value expected (\"true\" or \"false\")", attribute, self)
		}
	}



	open func getSize(_ attribute: DeclarationAttribute) throws -> CGSize {
		switch attribute.value {
			case .value(let string):
				let size = try parseFloat(string, attribute: attribute)
				return CGSize(width: size, height: size)
			case .list(let values):
				if values.count == 2 {
					return CGSize(width: try getFloat(attribute, values[0]), height: try getFloat(attribute, values[1]))
				}
				throw DeclarationError("Size value must contains single number or two numbers (width, height)", attribute, self)
			default:
				throw DeclarationError("Missing size value", attribute, self)
		}
	}



	open func getInsets(_ attribute: DeclarationAttribute) throws -> UIEdgeInsets {
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



	public final func applyInsets(_ insets: inout UIEdgeInsets, name: String, attribute: DeclarationAttribute) throws -> Bool {
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



	open func getColor(_ attribute: DeclarationAttribute) throws -> UIColor {
		switch attribute.value {
			case .value(let string):
				return UIColor.parse(string)
			default:
				throw DeclarationError("Missing color value", attribute, self)
		}
	}



	public final func getFont(_ attribute: DeclarationAttribute, defaultFont: UIFont?) throws -> UIFont {
		return try getFont(attribute, value: attribute.value, defaultFont: defaultFont ?? UIFont.systemFont(ofSize: UIFont.systemFontSize))
	}


	// MARK: - Internals


	private func font(_ font: UIFont, withTrait trait: UIFontDescriptorSymbolicTraits) -> UIFont {
		let descriptor = font.fontDescriptor
		if let descriptorWithTraits = descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(trait)) {
			return UIFont(descriptor: descriptorWithTraits, size: font.pointSize)
		}
		return font
	}



	public final func getFont(_ attribute: DeclarationAttribute, value: DeclarationValue, defaultFont: UIFont) throws -> UIFont {
		switch value {
			case .value(let string):

				if #available(iOS 9, *) {
					if let style = DeclarationContext.textStyleByName[string] {
						return UIFont.preferredFont(forTextStyle: style)
					}
				}
				if string == "bold" {
					return font(defaultFont, withTrait: UIFontDescriptorSymbolicTraits.traitBold)
				}
				if string == "italic" {
					return font(defaultFont, withTrait: UIFontDescriptorSymbolicTraits.traitItalic)
				}

				if let delta = float(from: string, prefix: "+", suffix: nil) {
					return defaultFont.withSize(defaultFont.pointSize + delta)
				}
				if let delta = float(from: string, prefix: "-", suffix: nil) {
					return defaultFont.withSize(defaultFont.pointSize - delta)
				}
				if let ratio = float(from: string, prefix: "*", suffix: nil) {
					return defaultFont.withSize(defaultFont.pointSize * ratio)
				}
				if let percent = float(from: string, prefix: nil, suffix: "%") {
					return defaultFont.withSize(defaultFont.pointSize * percent / 100)
				}
				if let size = float(from: string, prefix: nil, suffix: nil) {
					return defaultFont.withSize(size)
				}
				return UIFont(name: string, size: defaultFont.pointSize) ?? defaultFont
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



	private func float(from: String, prefix: String?, suffix: String?) -> CGFloat? {
		var string: String
		if let prefix = prefix {
			if !from.hasPrefix(prefix) {
				return nil
			}
			string = from.substring(from: from.index(from.startIndex, offsetBy: 1))
		}
		else if let suffix = suffix {
			if !from.hasSuffix(suffix) {
				return nil
			}
			string = from.substring(to: from.index(from.endIndex, offsetBy: -1))
		}
		else {
			string = from
		}
		var size = Float(0)
		if Scanner(string: string).scanFloat(&size) {
			return CGFloat(size)
		}
		return nil
	}


	@available(iOS 9.0, *)
	private static let textStyleByName: [String: UIFontTextStyle] = [
		"@title1": .title1,
		"@title2": .title2,
		"@title3": .title3,
		"@headline": .headline,
		"@subheadline": .subheadline,
		"@body": .body,
		"@footnote": .footnote,
		"@caption1": .caption1,
		"@caption2": .caption2,
		"@callout": .callout
	]

	private func parseFloat(_ string: String, attribute: DeclarationAttribute) throws -> CGFloat {
		var value: Float = 0
		if Scanner(string: string).scanFloat(&value) {
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
