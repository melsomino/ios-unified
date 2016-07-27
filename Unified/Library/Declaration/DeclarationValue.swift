//
// Created by Michael Vlasov on 16.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit


public struct DeclarationError: ErrorType, CustomStringConvertible {
	let message: String

	init(message: String, scanner: NSScanner?) {
		if scanner != nil {
			self.message = "\(message): \(scanner!.string.substringFromIndex(scanner!.string.startIndex.advancedBy(scanner!.scanLocation)))"
		}
		else {
			self.message = message
		}
	}

	// MARK: - CustomStringConvertible

	public var description: String {
		return message
	}

}


public class DeclarationContext {

	public var bindings = UiBindings()
	public var hasBindings = false

	init(_ elements: [DeclarationElement]) {

	}

	public func getFloat(attribute: DeclarationAttribute, _ value: DeclarationValue) throws -> CGFloat {
		switch value {
			case .Value(let string):
				return try parseFloat(string, attribute: attribute)
			default:
				throw DeclarationError(message: "Number value expected", scanner: nil)
		}
	}

	public func getFloat(attribute: DeclarationAttribute) throws -> CGFloat {
		return try getFloat(attribute, attribute.value)
	}

	public func getEnum<Enum>(attribute: DeclarationAttribute, _ valuesByLowercaseName: [String:Enum]) throws -> Enum {
		switch attribute.value {
			case .Value(let value):
				if let resolved = valuesByLowercaseName[value.lowercaseString] {
					return resolved
				}
				throw DeclarationError(message: "Invalid value \"\(value)\" for attribute \"\(attribute.name)\"", scanner: nil)
			default:
				throw DeclarationError(message: "Invalid value", scanner: nil)
		}
	}

	public func getString(attribute: DeclarationAttribute, _ value: DeclarationValue) throws -> String {
		switch value {
			case .Value(let string):
				return string
			default:
				throw DeclarationError(message: "String value expected", scanner: nil)
		}
	}

	public func getString(attribute: DeclarationAttribute) throws -> String {
		return try getString(attribute, attribute.value)
	}


	public func getExpression(attribute: DeclarationAttribute, _ value: DeclarationValue) throws -> UiBindings.Expression? {
		switch value {
			case .Value(let string):
				hasBindings = true
				return bindings.parse(string)
			default:
				throw DeclarationError(message: "String value expected", scanner: nil)
		}
	}

	public func getExpression(attribute: DeclarationAttribute) throws -> UiBindings.Expression? {
		return try getExpression(attribute, attribute.value)
	}


	public func getImage(attribute: DeclarationAttribute) throws -> UIImage {
		return try getImage(attribute, value: attribute.value)
	}


	public func getImage(attribute: DeclarationAttribute, value: DeclarationValue) throws -> UIImage {
		switch value {
			case .Value(let string):
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
				throw DeclarationError(message: "Missing required image: \(string)", scanner: nil)
			default:
				throw DeclarationError(message: "Image name expected", scanner: nil)
		}
	}


	public func getBool(attribute: DeclarationAttribute) throws -> Bool {
		switch attribute.value {
			case .Value(let string):
				if "true".caseInsensitiveCompare(string) == NSComparisonResult.OrderedSame {
					return true
				}
				if "false".caseInsensitiveCompare(string) == NSComparisonResult.OrderedSame {
					return false
				}
				throw DeclarationError(message: "Boolean value expected (\"true\" or \"false\")", scanner: nil)
			case .Missing:
				return true
			default:
				throw DeclarationError(message: "Boolean value expected (\"true\" or \"false\")", scanner: nil)
		}
	}


	public func getSize(attribute: DeclarationAttribute) throws -> CGSize {
		switch attribute.value {
			case .Value(let string):
				let size = try parseFloat(string, attribute: attribute)
				return CGSizeMake(size, size)
			case .List(let values):
				if values.count == 2 {
					return CGSizeMake(try getFloat(attribute, values[0]), try getFloat(attribute, values[1]))
				}
				throw DeclarationError(message: "Size value must contains single number or two numbers (width, height)", scanner: nil)
			default:
				throw DeclarationError(message: "Missing size value", scanner: nil)
		}
	}


	public func getInsets(attribute: DeclarationAttribute) throws -> UIEdgeInsets {
		switch attribute.value {
			case .Value(let string):
				let inset = try parseFloat(string, attribute: attribute)
				return UIEdgeInsetsMake(inset, inset, inset, inset)
			case .List(let values):
				switch values.count {
					case 2:
						let x = try getFloat(attribute, values[0])
						let y = try getFloat(attribute, values[1])
						return UIEdgeInsetsMake(y, x, y, x)
					case 4:
						return UIEdgeInsetsMake(try getFloat(attribute, values[0]), try getFloat(attribute, values[1]), try getFloat(attribute, values[2]), try getFloat(attribute, values[3]))
					default:
						throw DeclarationError(message: "Inset values must contains single number or two numbers (horizontal, vertical) or four numbers (top, left, bottom, right)", scanner: nil)
				}
			default:
				throw DeclarationError(message: "Missing insets value", scanner: nil)
		}
	}


	public func getColor(attribute: DeclarationAttribute) throws -> UIColor {
		switch attribute.value {
			case .Value(let string):
				return UIColor.parse(string)
			default:
				throw DeclarationError(message: "Missing color value", scanner: nil)
		}
	}


	// MARK: - Internals


	private func parseFloat(string: String, attribute: DeclarationAttribute) throws -> CGFloat {
		var value: Float = 0
		if NSScanner(string: string).scanFloat(&value) {
			return CGFloat(value)
		}
		throw DeclarationError(message: "Number expected", scanner: nil)
	}




}



public enum DeclarationValue {
	case Missing
	case Value(String)
	case List([DeclarationValue])

	public var isMissing: Bool {
		switch self {
			case .Missing: return true
			default: return false
		}
	}


}
