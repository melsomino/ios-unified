//
// Created by Власов М.Ю. on 16.06.16.
// Copyright (c) 2016 melsomino. All rights reserved.
//

import Foundation
import UIKit

class LayoutLabelFactory: LayoutViewBoundFactory {
	var fontName: String?
	var fontSize: CGFloat?
	var maxLines = 0
	var nowrap = false
	var color: UIColor?

	override func create() -> LayoutItem {
		return LayoutLabel()
	}

	override func applyMarkupAttributeWithName(name: String, value: MarkupValue) throws {
		switch name {
			case "font":
				try applyFontValue(value)
			case "maxlines":
				maxLines = Int(try value.getFloat())
			case "nowrap":
				nowrap = try value.getBool()
			case "color":
				color = try value.getColor()
			default:
				try super.applyMarkupAttributeWithName(name, value: value)
		}
	}

	private func applyFontValue(value: MarkupValue) throws {
		switch value {
			case .Value(let string):
				var size: Float = 0
				if NSScanner(string: string).scanFloat(&size) {
					fontSize = CGFloat(size)
				}
				else {
					fontName = string
				}
			case .List(let values):
				for value in values {
					try applyFontValue(value)
				}
			default:
				throw LayoutMarkupError("Font attributes expected")
		}
	}

	override func apply(item: LayoutItem, _ content: [LayoutItem]) {
		super.apply(item, content)

		let label = item as! LayoutLabel
		if let name = fontName, size = fontSize {
			label.font = font(name, size)
		}
		else if let name = fontName {
			label.font = font(name, UIFont.systemFontSize())
		}
		else if let size = fontSize {
			label.font = UIFont.systemFontOfSize(size)
		}
		else {
			label.font = UIFont.systemFontOfSize(UIFont.systemFontSize())
		}
		label.maxLines = maxLines
		label.nowrap = nowrap

		if color != nil {
			let c = color
			label.initLabel = {
				label in
				if c != nil {
					label.textColor = c!
				}
			}
		}
	}

	func font(name: String, _ size: CGFloat) -> UIFont {
		return UIFont(name: name, size: size) ?? UIFont.systemFontOfSize(size)
	}
}
