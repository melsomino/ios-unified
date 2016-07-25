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
	private var measuredRange = StackRange.zero
	private var measuredSpacing: CGFloat = 0
	private var measuredSize = StackPosition()


	public override var visible: Bool {
		for item in children {
			if item.visible {
				return true
			}
		}
		return false
	}


	public override func measureSizeRange(inBounds bounds: CGSize) -> SizeRange {
		let horizontal = direction == .Horizontal
		let stackBounds = StackPosition(bounds, horizontal)
		measuredCount = 0
		measuredRange.min.clear()
		measuredRange.max.clear()
		measuredSpacing = 0
		measuredSize.clear()
		for child in children {
			guard child.visible else {
				continue
			}
			if measuredCount >= measured.count {
				measured.append(Measured())
			}
			let childRange = measured[measuredCount].measureSizeRange(forElement: child, inBounds: stackBounds, horizontal: horizontal)
			measuredCount += 1
			if measuredCount > 1 {
				measuredRange.min.along += spacing
				measuredRange.max.along += spacing
				measuredSpacing += spacing
			}
			measuredRange.min.along += childRange.min.along
			measuredRange.max.along += childRange.max.along
			measuredRange.min.across = max(childRange.across, measuredRange.min.across)
			measuredRange.max.across = max(childRange.across, measuredRange.max.across)
		}
		return measuredRange.toSizeRange(horizontal)
	}


	public override func measureSize(bounds: CGSize) -> CGSize {
		let horizontal = direction == .Horizontal
		let stackBounds = StackPosition(bounds, horizontal)
		measuredSize.clear()
		let extraSize = stackBounds.along - measuredRange.min.along
		for index in 0 ..< measuredCount {
			let item = measured[index]
			var itemBounds = StackPosition()
			itemBounds.across = stackBounds.across
			if item.content.fixedSize || extraSize <= 0 {
				itemBounds.along = item.maxSize.along
			}
			else {
				itemBounds.along = along == .Fill ? extraSize * item.maxSize.along / measuredNotFixedMaxSize : min(item.maxSize.along, stackBounds.along)
			}
			var itemSize = measured[index].measureSize(itemBounds, horizontal)
			if along == .Fill && !item.content.fixedSize && itemSize.along < itemBounds.along {
				itemSize.along = itemBounds.along
			}
			measured[index].size = itemSize
			if index > 0 {
				measuredSize.along += spacing
			}
			measuredSize.along += itemSize.along
			measuredSize.across = max(itemSize.across, measuredSize.across)

		}
		return measuredSize.toSize(horizontal)
	}


	private func calcMeasuredAlongSize() -> CGFloat {
		var size = CGFloat(0)
		for index in 0 ..< measuredCount {
			if index > 0 {
				size += spacing
			}
			size += measured[index].size.along
		}
		return size
	}


	public override func layout(bounds: CGRect) -> CGRect {
		guard measuredCount > 0 else {
			return bounds
		}

		let horizontal = direction == .Horizontal
		var stackOrigin = StackPosition(bounds.origin, horizontal)
		var stackBounds = StackPosition(bounds.size, horizontal)
		if across != .Fill && measuredSize.across < stackBounds.across {
			stackBounds.across = measuredSize.across
		}
		var spacing = self.spacing
		if along == .Fill && allMeasuredElementsHasFixedSize && measuredCount > 1 {
			spacing = (stackBounds.along - measuredFixedSize) / CGFloat(measuredCount - 1)
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

		return CGRect(origin: bounds.origin, size: measuredSize.toSize(horizontal))
	}

}





private struct StackPosition {
	var along: CGFloat = 0
	var across: CGFloat = 0

	static let zero = StackPosition()

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


private struct StackRange {
	var min: StackPosition = StackPosition.zero
	var max: StackPosition = StackPosition.zero

	static let zero = StackRange()

	convenience init(sizeRange: SizeRange, horizontal: Bool) {
		self.init(min: StackPosition(sizeRange.min, horizontal), max: StackPosition(sizeRange.max, horizontal))
	}

	func toSizeRange(horizontal: Bool) -> SizeRange {
		return SizeRange(min: min.toSize(horizontal), max: max.toSize(horizontal))
	}
}





private struct Measured {
	var element: UiElement!
	var sizeRange = StackRange()
	var size = StackPosition()

	init() {
	}


	mutating func measureSizeRange(forElement element: UiElement, inBounds: StackPosition, horizontal: Bool) -> StackPosition {
		self.element = element
		let elementSizeRange = element.measureSizeRange(inBounds: bounds.toSize(horizontal))
		sizeRange = StackRange(elementSizeRange, horizontal)
		return maxSize
	}


	mutating func measureSize(bounds: StackPosition, _ horizontal: Bool) -> StackPosition {
		size = StackPosition(element.measureSize(bounds.toSize(horizontal)), horizontal)
		return size
	}
}





class UiStackContainerDefinition: UiElementDefinition {
	let direction: UiStackDirection
	var along = UiAlignment.Fill
	var across = UiAlignment.Leading
	var spacing = CGFloat(0)


	init(direction: UiStackDirection) {
		self.direction = direction
		along = direction == .Horizontal ? .Fill : .Leading
		across = direction == .Horizontal ? .Leading : .Fill
	}


	override func createElement() -> UiElement {
		return UiStackContainer()
	}


	override func initialize(element: UiElement, children: [UiElement]) {
		super.initialize(element, children: children)
		let stack = element as! UiStackContainer
		stack.direction = direction
		stack.along = along
		stack.across = across
		stack.spacing = spacing
		stack.children = children
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

