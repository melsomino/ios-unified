//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public enum UiStackDirection {
	case Horizontal, Vertical
}




public class UiStackContainer: UiMultipleElementContainer {

	var direction = UiStackDirection.Vertical
	var along = UiAlignment.Fill
	var across = UiAlignment.Leading
	var spacing = CGFloat(0)

	private var measured = [Measured]()
	private var measuredCount = 0
	private var maxSize = StackPosition()
	private var fixedSpace: CGFloat = 0
	private var notFixedMaxSpace: CGFloat = 0
	private var spacingSize: CGFloat = 0
	private var size = StackPosition()


	public override var visible: Bool {
		for item in children {
			if item.visible {
				return true
			}
		}
		return false
	}


	public override func measureMaxSize(bounds: CGSize) -> CGSize {
		let horizontal = direction == .Horizontal
		let stackBounds = StackPosition(bounds, horizontal)
		measuredCount = 0
		maxSize.clear()
		spacingSize = 0
		fixedSpace = 0
		notFixedMaxSpace = 0
		for item in children {
			if item.visible {
				if measuredCount >= measured.count {
					measured.append(Measured())
				}
				let itemMaxSize = measured[measuredCount].measureMaxSize(item, stackBounds, horizontal)
				measuredCount += 1
				if measuredCount > 1 {
					maxSize.along += spacing
					spacingSize += spacing
				}
				maxSize.along += itemMaxSize.along
				maxSize.across = max(itemMaxSize.across, maxSize.across)
				if item.fixedSize {
					fixedSpace += itemMaxSize.along
				}
				else {
					notFixedMaxSpace += itemMaxSize.along
				}
			}
		}
		return maxSize.toSize(horizontal)
	}





	public override func measureSize(bounds: CGSize) -> CGSize {
		let horizontal = direction == .Horizontal
		let stackBounds = StackPosition(bounds, horizontal)
		size.clear()
		let nonFixedSpace = stackBounds.along - spacingSize - fixedSpace
		for index in 0 ..< measuredCount {
			let item = measured[index]
			var itemBounds = StackPosition()
			itemBounds.across = stackBounds.across
			if item.content.fixedSize || nonFixedSpace <= 0 {
				itemBounds.along = item.maxSize.along
			}
			else {
				itemBounds.along = along == .Fill ? nonFixedSpace * item.maxSize.along / notFixedMaxSpace : min(item.maxSize.along, stackBounds.along)
			}
			var itemSize = measured[index].measureSize(itemBounds, horizontal)
			if along == .Fill && !item.content.fixedSize && itemSize.along < itemBounds.along {
				itemSize.along = itemBounds.along
			}
			measured[index].size = itemSize
			if index > 0 {
				size.along += spacing
			}
			size.along += itemSize.along
			size.across = max(itemSize.across, size.across)

		}
		return size.toSize(horizontal)
	}



	private func calcMeasuredAlongSize() -> CGFloat {
		var size = CGFloat(0)
		for index in 0 ..< measuredCount {
			if  index > 0 {
				size += spacing
			}
			size += measured[index].size.along
		}
		return size
	}


	public override func layout(bounds: CGRect) -> CGRect {
		let horizontal = direction == .Horizontal
		var stackOrigin = StackPosition(bounds.origin, horizontal)
		var stackBounds = StackPosition(bounds.size, horizontal)
		if across != .Fill && size.across < stackBounds.across {
			stackBounds.across = size.across
		}

		switch along {
			case .Center:
				stackOrigin.along = stackOrigin.along + stackBounds.along / 2 - calcMeasuredAlongSize() / 2
			case .Tailing:
				stackOrigin.along = stackOrigin.along + stackBounds.along - calcMeasuredAlongSize()
			default:
				break
		}

		for index in 0 ..< measuredCount {
			let item = measured[index]
			var itemOrigin = stackOrigin
			var itemSize = item.size

			switch across {
				case .Tailing:
					itemOrigin.across = stackOrigin.across + stackBounds.across - itemSize.across
				case .Center:
					itemOrigin.across = stackOrigin.across + stackBounds.across / 2 - itemSize.across / 2
				default:
					itemSize.across = stackBounds.across
			}

			item.content.layout(CGRect(origin: itemOrigin.toPoint(horizontal), size: itemSize.toSize(horizontal)))

			stackOrigin.along += itemSize.along + spacing
		}

		return CGRect(origin: bounds.origin, size: size.toSize(horizontal))
	}

}





private struct StackPosition {
	var along: CGFloat = 0
	var across: CGFloat = 0

	init() {

	}

	init(_ along: CGFloat, _ across: CGFloat) {
		self.along = along
		self.across = across
	}

	init(_ size: CGSize, _ horizontal: Bool) {
		self.along = horizontal ? size.width : size.height
		self.across = horizontal ? size.height : size.width
	}

	init(_ point: CGPoint, _ horizontal: Bool) {
		self.along = horizontal ? point.x : point.y
		self.across = horizontal ? point.y : point.x
	}

	mutating func clear() {
		along = 0
		across = 0
	}

	func toSize(horizontal: Bool) -> CGSize {
		return CGSizeMake(horizontal ? along : across, horizontal ? across : along)
	}

	func toPoint(horizontal: Bool) -> CGPoint {
		return CGPointMake(horizontal ? along : across, horizontal ? across : along)
	}

}





private struct Measured {
	var content: UiElement!
	var maxSize = StackPosition()
	var size = StackPosition()

	init() {
	}

	mutating func measureMaxSize(content: UiElement, _ bounds: StackPosition, _ horizontal: Bool) -> StackPosition {
		self.content = content
		let contentMaxSize = content.measureMaxSize(bounds.toSize(horizontal))
		maxSize = StackPosition(contentMaxSize, horizontal)
		return maxSize
	}

	mutating func measureSize(bounds: StackPosition, _ horizontal: Bool) -> StackPosition {
		size = StackPosition(content.measureSize(bounds.toSize(horizontal)), horizontal)
		return size
	}
}





class UiStackContainerFactory: UiElementDefinition {
	let direction: UiStackDirection
	var along = UiAlignment.Fill
	var across = UiAlignment.Leading
	var spacing = CGFloat(0)


	init(direction: UiStackDirection) {
		self.direction = direction
		along = direction == .Horizontal ? .Fill : .Leading
		across = direction == .Horizontal ? .Leading : .Fill
	}


	override func create() -> UiElement {
		return UiStackContainer()
	}

	override func initialize(item: UiElement, content: [UiElement]) {
		super.initialize(item, children: content)
		let stack = item as! UiStackContainer
		stack.direction = direction
		stack.along = along
		stack.across = across
		stack.spacing = spacing
		stack.children = content
	}


	override func applyDeclarationAttribute(attribute: DeclarationAttribute, context: DeclarationContext) throws {
		switch attribute.name {
			case "along":
				along = try context.getEnum(attribute, UiElementDefinition.alignments)
			case "across":
				across = try context.getEnum(attribute, UiElementDefinition.alignments)
			case "spacing":
				spacing = try context.getFloat(attribute)
			default:
				try super.applyDeclarationAttribute(attribute, context: context)
		}
	}

}

