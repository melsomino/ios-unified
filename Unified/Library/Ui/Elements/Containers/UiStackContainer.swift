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

	public override var visible: Bool {
		for item in children {
			if item.visible {
				return true
			}
		}
		return false
	}


	public override func measureContent(inBounds bounds: CGSize) -> SizeRange {
		var measure = StackMeasure(stack: self, inLayoutBounds: bounds)
		var sizeRange = measure.measure().toSizeRange(measure.horizontal)
		if sizeRange.max.width > bounds.width {
			sizeRange.max.width = bounds.width
		}
		return sizeRange
	}


	public override func layoutContent(inBounds bounds: CGRect) -> CGRect {
		var measure = StackMeasure(stack: self, inLayoutBounds: bounds.size)
		return measure.layout(inLayoutBounds: bounds)
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
	var min: StackPosition
	var max: StackPosition

	static let zero = StackRange(min: StackPosition.zero, max: StackPosition.zero)

	init(min: StackPosition, max: StackPosition) {
		self.min = min
		self.max = max
	}

	init(sizeRange: SizeRange, horizontal: Bool) {
		self.init(min: StackPosition(sizeRange.min, horizontal), max: StackPosition(sizeRange.max, horizontal))
	}


	func toSizeRange(horizontal: Bool) -> SizeRange {
		return SizeRange(min: min.toSize(horizontal), max: max.toSize(horizontal))
	}
}





private struct StackChildMeasure {
	let element: UiElement
	let horizontal: Bool
	let alongAlign: UiAlignment
	var sizeRange = StackRange.zero
	var size = StackPosition()

	init(element: UiElement, horizontal: Bool) {
		self.element = element
		self.horizontal = horizontal
		alongAlign = horizontal ? element.halign : element.valign
	}


	mutating func measure(inBounds bounds: StackPosition, horizontal: Bool) -> StackRange {
		let elementSizeRange = element.measure(inBounds: bounds.toSize(horizontal))
		sizeRange = StackRange(sizeRange: elementSizeRange, horizontal: horizontal)
		if alongAlign == .Fill {
			sizeRange.max.along = bounds.along
		}
		return sizeRange
	}


	mutating func measureSize(stackBounds stackBounds: StackPosition,
		stackMeasuredExtraAlong: CGFloat, stackActualExtraAlong: CGFloat,
		horizontal: Bool, stackAlong: UiAlignment, stackAcross: UiAlignment, childrenCount: Int) -> StackPosition {

		size = StackPosition(sizeRange.min.along, 0)
		if stackActualExtraAlong > 0 {
			if childrenCount == 1 && stackAlong == .Fill {
				size.along += stackActualExtraAlong
			}
			else {
				let measuredChildExtraAlong = sizeRange.max.along - sizeRange.min.along
				if stackMeasuredExtraAlong > 0 {
					size.along += stackActualExtraAlong * measuredChildExtraAlong / stackMeasuredExtraAlong
				}
			}
		}
		if stackAcross == .Fill {
			size.across = stackBounds.across
		}
		sizeRange = measure(inBounds: size, horizontal: horizontal)
		size.across = sizeRange.max.across
		return size
	}

}





private struct StackMeasure {
	let stack: UiStackContainer
	let horizontal: Bool
	let bounds: StackPosition
	let spacing: CGFloat

	var children = [StackChildMeasure]()

	init(stack: UiStackContainer, inLayoutBounds layoutBounds: CGSize) {
		self.stack = stack
		self.horizontal = stack.direction == .Horizontal
		self.bounds = StackPosition(layoutBounds, horizontal)

		for child in stack.children {
			if child.visible {
				children.append(StackChildMeasure(element: child, horizontal: horizontal))
			}
		}

		spacing = CGFloat(children.count - 1) * stack.spacing
	}


	mutating func measure() -> StackRange {
		var sizeRange = StackRange.zero
		for i in 0 ..< children.count {
			let childRange = children[i].measure(inBounds: bounds, horizontal: horizontal)
			sizeRange.min.along += childRange.min.along
			sizeRange.min.across = max(childRange.min.across, sizeRange.min.across)

			sizeRange.max.along += childRange.max.along
			sizeRange.max.across = max(childRange.max.across, sizeRange.max.across)
		}
		sizeRange.min.along += spacing
		sizeRange.max.along += spacing
		return sizeRange
	}


	mutating func layout(inLayoutBounds layoutBounds: CGRect) -> CGRect {
		guard children.count > 0 else {
			return CGRect(origin: layoutBounds.origin, size: CGSizeZero)
		}

		let sizeRange: StackRange = measure()
		let measuredExtraSize = sizeRange.max.along - sizeRange.min.along
		let actualExtraSize = bounds.along - sizeRange.min.along
		var stackOrigin = StackPosition(layoutBounds.origin, horizontal)

		var itemSpacing = stack.spacing
		var maxSize = StackPosition.zero
		for i in 0 ..< children.count {
			let itemSize = children[i].measureSize(stackBounds: bounds,
				stackMeasuredExtraAlong: measuredExtraSize, stackActualExtraAlong: actualExtraSize, horizontal: horizontal,
				stackAlong: stack.along, stackAcross: stack.across, childrenCount: children.count)
			maxSize.along += itemSize.along
			maxSize.across = max(maxSize.across, itemSize.across)
		}

		if stack.across == .Fill && maxSize.across < bounds.across {
			maxSize.across = bounds.across
		}

		var totalSpacing = spacing

		if stack.along == .Fill && children.count > 1 && maxSize.along + spacing < bounds.along {
			totalSpacing = bounds.along - maxSize.along
			itemSpacing = totalSpacing / CGFloat(children.count - 1)
		}

		switch stack.along {
			case .Center:
				stackOrigin.along = stackOrigin.along + bounds.along / 2 - (maxSize.along + totalSpacing) / 2
			case .Tailing:
				stackOrigin.along = stackOrigin.along + bounds.along - (maxSize.along + totalSpacing)
			default:
				break
		}


		var size = StackPosition(totalSpacing, 0)
		for index in 0 ..< children.count {
			let child: StackChildMeasure = children[index]
			var itemOrigin = stackOrigin
			var itemBounds = child.size

			switch stack.across {
				case .Tailing:
					itemOrigin.across = stackOrigin.across + maxSize.across - itemBounds.across
				case .Center:
					itemOrigin.across = stackOrigin.across + maxSize.across / 2 - itemBounds.across / 2
				default:
					break
			}

			if stack.across == .Fill {
				itemBounds.across = maxSize.across
			}
			let childFrame = child.element.align(withSize: itemBounds.toSize(horizontal), inBounds: CGRect(origin: itemOrigin.toPoint(horizontal), size: itemBounds.toSize(horizontal)))
			let childSize = StackPosition(childFrame.size, horizontal)
			if childSize.along > itemBounds.along {
				itemBounds.along = childSize.along
			}

			stackOrigin.along += itemBounds.along + itemSpacing
			size.along += itemBounds.along
			size.across = max(size.across, itemBounds.across)
		}

		return CGRect(origin: layoutBounds.origin, size: size.toSize(horizontal))
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

