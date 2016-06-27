//
// Created by Michael Vlasov on 16.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

class LayoutTextFactory: LayoutViewItemFactory {
	var fontName: String?
	var fontSize: CGFloat?
	var maxLines = 0
	var nowrap = false
	var color: UIColor?

	override func create() -> LayoutItem {
		return LayoutText()
	}

	override func applyDeclarationAttribute(attribute: DeclarationAttribute, context: DeclarationContext) throws {
		switch attribute.name {
			case "font":
				try applyFontValue(attribute, value: attribute.value, context: context)
			case "max-lines":
				maxLines = Int(try context.getFloat(attribute))
			case "nowrap":
				nowrap = try context.getBool(attribute)
			case "color":
				color = try context.getColor(attribute)
			default:
				try super.applyDeclarationAttribute(attribute, context: context)
		}
	}

	private func applyFontValue(attribute: DeclarationAttribute, value: DeclarationValue, context: DeclarationContext) throws {
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
					try applyFontValue(attribute, value: value, context: context)
				}
			default:
				throw DeclarationError(message: "Font attributes expected", scanner: nil)
		}
	}

	override func initialize(item: LayoutItem, content: [LayoutItem]) {
		super.initialize(item, content: content)

		let label = item as! LayoutText
		if let name = fontName, size = fontSize {
			label.font = font(name, size)
		}
		else if let name = fontName {
			label.font = font(name, UIFont.systemFontSize())
		}
		else if let size = fontSize {
			label.font = UIFont.systemFontOfSize(size)
		}
		label.color = color
		label.maxLines = maxLines
		label.nowrap = nowrap
	}

	func font(name: String, _ size: CGFloat) -> UIFont {
		return UIFont(name: name, size: size) ?? UIFont.systemFontOfSize(size)
	}
}
