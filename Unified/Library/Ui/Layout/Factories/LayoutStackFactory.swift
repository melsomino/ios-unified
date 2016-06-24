//
// Created by Власов М.Ю. on 16.06.16.
// Copyright (c) 2016 melsomino. All rights reserved.
//

import Foundation


class LayoutStackFactory: LayoutItemFactory {
	let direction: LayoutStackDirection
	var along = LayoutAlignment.Fill
	var across = LayoutAlignment.Leading
	var spacing = CGFloat(0)


	init(direction: LayoutStackDirection) {
		self.direction = direction
		along = direction == .Horizontal ? .Fill : .Leading
		across = direction == .Horizontal ? .Leading : .Fill
	}


	override func create() -> LayoutItem {
		return LayoutStack()
	}

	override func initialize(item: LayoutItem, content: [LayoutItem]) {
		super.initialize(item, content: content)
		let stack = item as! LayoutStack
		stack.direction = direction
		stack.along = along
		stack.across = across
		stack.spacing = spacing
		stack.content = content
	}


	override func applyDeclarationAttribute(attribute: DeclarationAttribute, context: DeclarationContext) throws {
		switch attribute.name {
			case "along":
				along = try context.getEnum(attribute, LayoutItemFactory.alignments)
			case "across":
				across = try context.getEnum(attribute, LayoutItemFactory.alignments)
			case "spacing":
				spacing = try context.getFloat(attribute)
			default:
				try super.applyDeclarationAttribute(attribute, context: context)
		}
	}

}

