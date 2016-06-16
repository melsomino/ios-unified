//
// Created by Власов М.Ю. on 16.06.16.
// Copyright (c) 2016 melsomino. All rights reserved.
//

import Foundation
import UIKit


public enum MarkupValue {
	case Missing
	case Value(String)
	case List([MarkupValue])

	public var missing: Bool {
		switch self {
			case .Missing: return true
			default: return false
		}
	}

	public func getEnum<Enum>(valuesByLowercaseName: [String:Enum]) throws -> Enum {
		switch self {
			case Value(let value):
				return valuesByLowercaseName[value.lowercaseString]!
			default:
				throw LayoutMarkupError("Invalid value")
		}
	}


	private func parseFloat(string: String) throws -> CGFloat {
		var value: Float = 0
		if NSScanner(string: string).scanFloat(&value) {
			return CGFloat(value)
		}
		throw LayoutMarkupError("Number expected")
	}


	public func getString() throws -> String {
		switch self {
			case Value(let string):
				return string
			default:
				throw LayoutMarkupError("String value expected")
		}
	}


	public func getFloat() throws -> CGFloat {
		switch self {
			case Value(let string):
				return try parseFloat(string)
			default:
				throw LayoutMarkupError("Number value expected")
		}
	}


	public func getBool() throws -> Bool {
		switch self {
			case Value(let string):
				if "true".caseInsensitiveCompare(string) == NSComparisonResult.OrderedSame {
					return true
				}
				if "false".caseInsensitiveCompare(string) == NSComparisonResult.OrderedSame {
					return false
				}
				throw LayoutMarkupError("Boolean value expected (\"true\" or \"false\")")
			case Missing:
				return true
			default:
				throw LayoutMarkupError("Boolean value expected (\"true\" or \"false\")")
		}
	}


	public func getSize() throws -> CGSize {
		switch self {
			case Value(let string):
				let size = try parseFloat(string)
				return CGSizeMake(size, size)
			case List(let values):
				if values.count == 2 {
					return CGSizeMake(try values[0].getFloat(), try values[1].getFloat())
				}
				throw LayoutMarkupError("Size value must contains single number or two numbers (width, height)")
			default:
				throw LayoutMarkupError("Missing size value")
		}
	}


	public func getInsets() throws -> UIEdgeInsets {
		switch self {
			case Value(let string):
				let inset = try parseFloat(string)
				return UIEdgeInsetsMake(inset, inset, inset, inset)
			case List(let values):
				switch values.count {
					case 2:
						let x = try values[0].getFloat()
						let y = try values[1].getFloat()
						return UIEdgeInsetsMake(y, x, y, x)
					case 4:
						return UIEdgeInsetsMake(try values[0].getFloat(), try values[1].getFloat(), try values[2].getFloat(), try values[3].getFloat())
					default:
						throw LayoutMarkupError("Inset values must contains single number or two numbers (horizontal, vertical) or four numbers (top, left, bottom, right)")
				}
			default:
				throw LayoutMarkupError("Missing insets value")
		}
	}


	public func getColor() throws -> UIColor {
		switch self {
			case Value(let string):
				if let named = MarkupValue.colorsByName[string.lowercaseString] {
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
			default:
				throw LayoutMarkupError("Missing color value")
		}
	}

	static let colorsByName = [
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
