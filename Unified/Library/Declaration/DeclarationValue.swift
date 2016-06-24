//
// Created by Michael Vlasov on 16.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit


public struct DeclarationError: ErrorType {
	let message: String
	init(message: String, scanner: NSScanner?) {
		if scanner != nil {
			self.message = "\(message): \(scanner!.string.substringFromIndex(scanner!.string.startIndex.advancedBy(scanner!.scanLocation)))"
		}
		else {
			self.message = message
		}
	}
}


public struct DeclarationContext {

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
				return valuesByLowercaseName[value.lowercaseString]!
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
				return DeclarationContext.parseColor(string)
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


	private static func parseColor(string: String) -> UIColor {
		if let named = DeclarationContext.colorsByName[string.lowercaseString] {
			return named
		}
		let hex = string.stringByTrimmingCharactersInSet(NSCharacterSet.alphanumericCharacterSet().invertedSet)
		var int = UInt32()
		NSScanner(string: hex).scanHexInt(&int)
		let a, r, g, b: UInt32
		switch hex.characters.count {
			case 3: // RGB (12-bit)
				(a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
			case 6: // RGB (24-bit)
				(a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
			case 8: // ARGB (32-bit)
				(a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
			default:
				(a, r, g, b) = (1, 1, 1, 0)
		}
		return UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
	}


	private static let colorsByName = [
		"black": UIColor.blackColor(),
		"darkGray": UIColor.darkGrayColor(),
		"lightGray": UIColor.lightGrayColor(),
		"white": UIColor.whiteColor(),
		"gray": UIColor.grayColor(),
		"red": UIColor.redColor(),
		"green": UIColor.greenColor(),
		"blue": UIColor.blueColor(),
		"cyan": UIColor.cyanColor(),
		"yellow": UIColor.yellowColor(),
		"magenta": UIColor.magentaColor(),
		"orange": UIColor.orangeColor(),
		"purple": UIColor.purpleColor(),
		"brown": UIColor.brownColor(),
		"clear": UIColor.clearColor()
	]


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
