//
// Created by Michael Vlasov on 16.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit


class LayoutViewItemFactory: LayoutItemFactory {
	var backgroundColor: UIColor?
	var cornerRadius: CGFloat?

	override func applyDeclarationAttribute(attribute: DeclarationAttribute, context: DeclarationContext) throws {
		switch attribute.name {
			case "background":
				backgroundColor = try context.getColor(attribute)
			case "corner-radius":
				cornerRadius = try context.getFloat(attribute)
			default:
				try super.applyDeclarationAttribute(attribute, context: context)
		}
	}

	override func initialize(item: LayoutItem, content: [LayoutItem]) {
		super.initialize(item, content: content)
		let viewItem = item as! LayoutViewItem
		viewItem.backgroundColor = backgroundColor
		viewItem.cornerRadius = cornerRadius
	}

}





class LayoutViewFactory: LayoutViewItemFactory {
	var size = CGSizeZero
	var fixedSize = false

	override func create() -> LayoutItem {
		return LayoutView()
	}

	override func initialize(item: LayoutItem, content: [LayoutItem]) {
		super.initialize(item, content: content)
		let view = item as! LayoutView
		view.size = size
		view.fixedSizeValue = fixedSize
	}

	override func applyDeclarationAttribute(attribute: DeclarationAttribute, context: DeclarationContext) throws {
		switch attribute.name {
			case "size":
				size = try context.getSize(attribute)
			case "fixed-size":
				fixedSize = try context.getBool(attribute)
			default:
				try super.applyDeclarationAttribute(attribute, context: context)
		}
	}

}





