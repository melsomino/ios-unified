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
		var measure = Stack_measure(stack: self, in_layout_bounds: bounds)
		measure.measure()
		var size_range = measure.size_range.to_size_range(measure.in_horizontal_direction)
		if size_range.max.width > bounds.width {
			size_range.max.width = bounds.width
		}
		return size_range
	}


	public override func layoutContent(inBounds bounds: CGRect) -> CGRect {
		var measure = Stack_measure(stack: self, in_layout_bounds: bounds.size)
		return measure.layout(in_layout_bounds: bounds)
	}

}





private struct Stack_unit {
	var along: CGFloat = 0
	var across: CGFloat = 0

	static let zero = Stack_unit()

	init() {

	}

	init(_ along: CGFloat, _ across: CGFloat) {
		self.along = along
		self.across = across
	}

	init(_ size: CGSize, _ in_horizontal_direction: Bool) {
		self.along = in_horizontal_direction ? size.width : size.height
		self.across = in_horizontal_direction ? size.height : size.width
	}

	init(_ point: CGPoint, _ in_horizontal_direction: Bool) {
		self.along = in_horizontal_direction ? point.x : point.y
		self.across = in_horizontal_direction ? point.y : point.x
	}


	mutating func clear() {
		along = 0
		across = 0
	}


	func to_size(in_horizontal_direction: Bool) -> CGSize {
		return CGSizeMake(in_horizontal_direction ? along : across, in_horizontal_direction ? across : along)
	}


	func to_point(in_horizontal_direction: Bool) -> CGPoint {
		return CGPointMake(in_horizontal_direction ? along : across, in_horizontal_direction ? across : along)
	}

}





private struct Stack_range {
	var min: Stack_unit
	var max: Stack_unit

	static let zero = Stack_range(min: Stack_unit.zero, max: Stack_unit.zero)

	init(min: Stack_unit, max: Stack_unit) {
		self.min = min
		self.max = max
	}

	init(_ size_range: SizeRange, _ in_horizontal_direction: Bool) {
		self.init(min: Stack_unit(size_range.min, in_horizontal_direction), max: Stack_unit(size_range.max, in_horizontal_direction))
	}


	func to_size_range(in_horizontal_direction: Bool) -> SizeRange {
		return SizeRange(min: min.to_size(in_horizontal_direction), max: max.to_size(in_horizontal_direction))
	}
}





private struct Stack_child_measure {
	let element: UiElement
	let in_horizontal_direction: Bool
	let along_alignment: UiAlignment
	let across_alignment: UiAlignment

	var size_range = Stack_range.zero

	var bounds_along = CGFloat(0)
	var size = Stack_unit.zero

	init(_ element: UiElement, _ in_horizontal_direction: Bool) {
		self.element = element
		self.in_horizontal_direction = in_horizontal_direction
		along_alignment = in_horizontal_direction ? element.horizontalAlignment : element.verticalAlignment
		across_alignment = in_horizontal_direction ? element.verticalAlignment : element.horizontalAlignment
	}


	mutating func measure_size_range(in_bounds bounds: Stack_unit) -> Stack_range {
		let element_size_range = element.measure(inBounds: bounds.to_size(in_horizontal_direction))
		size_range = Stack_range(element_size_range, in_horizontal_direction)
		return size_range
	}

	mutating func measure_bounds_by_reducing_min_size(ratio: CGFloat) {
		bounds_along = size_range.min.along * ratio
	}

	mutating func measure_bounds_by_reducing_extra_space(ratio:CGFloat) {
		bounds_along = size_range.min.along + (size_range.max.along - size_range.min.along) * ratio
	}

	mutating func measure_bounds_by_max_size() {
		bounds_along = size_range.max.along
	}

	mutating func measure_size(bounds_across: CGFloat) -> Stack_unit {
		let element_size_range = element.measure(inBounds: Stack_unit(bounds_along, bounds_across).to_size(in_horizontal_direction))
		size = Stack_unit(element_size_range.max, in_horizontal_direction)
		if size.along > bounds_along {
			size.along = bounds_along
		}
		return size
	}

}





private struct Stack_measure {
	let stack: UiStackContainer
	let in_horizontal_direction: Bool
	let bounds: Stack_unit
	let total_spacing: CGFloat
	var children = [Stack_child_measure]()

	var size_range = Stack_range.zero

	init(stack: UiStackContainer, in_layout_bounds layout_bounds: CGSize) {
		self.stack = stack
		self.in_horizontal_direction = stack.direction == .Horizontal
		self.bounds = Stack_unit(layout_bounds, in_horizontal_direction)
		for child in stack.children {
			if child.visible {
				children.append(Stack_child_measure(child, in_horizontal_direction))
			}
		}
		total_spacing = CGFloat(children.count - 1) * stack.spacing
	}


	mutating func measure() {
		var size_range = Stack_range.zero
		for i in 0 ..< children.count {
			let child_size_range = children[i].measure_size_range(in_bounds: bounds)
			size_range.min.along += child_size_range.min.along
			size_range.min.across = max(child_size_range.min.across, size_range.min.across)

			size_range.max.along += child_size_range.max.along
			size_range.max.across = max(child_size_range.max.across, size_range.max.across)
		}
		size_range.min.along += total_spacing
		size_range.max.along += total_spacing
		self.size_range = size_range
	}


	mutating func measure_children_bounds_by_reducing_min_sizes() {
		let total_min_along = size_range.min.along - total_spacing
		let actual_along = bounds.along - total_spacing
		let min_size_ratio = actual_along / total_min_along
		for i in 0 ..< children.count {
			children[i].measure_bounds_by_reducing_min_size(min_size_ratio)
		}
	}

	mutating func measure_children_bounds_by_filling_extra_space() {
		let total_extra_along = size_range.max.along - size_range.min.along
		guard total_extra_along > 0 else {
			measure_children_bounds_by_reducing_min_sizes()
			return
		}
		let actual_extra_along = bounds.along - size_range.min.along
		let extra_space_ratio = actual_extra_along / total_extra_along
		for i in 0 ..< children.count {
			children[i].measure_bounds_by_reducing_extra_space(extra_space_ratio)
		}
	}

	mutating func measure_children_bounds() {
		for i in 0 ..< children.count {
			children[i].bounds_along = children[i].size_range.max.along
		}
	}

	mutating func layout(in_layout_bounds layout_bounds: CGRect) -> CGRect {
		guard children.count > 0 else {
			return CGRect(origin: layout_bounds.origin, size: CGSizeZero)
		}

		measure()

		let fill_along = stack.along == .Fill
		let fill_across = stack.across == .Fill

		if fill_along {
			if size_range.min.along >= bounds.along {
				measure_children_bounds_by_reducing_min_sizes()
			}
			else {
				measure_children_bounds_by_filling_extra_space()
			}
		}
		else {
			if size_range.min.along >= bounds.along {
				measure_children_bounds_by_reducing_min_sizes()
			}
			else if size_range.max.along > bounds.along {
				measure_children_bounds_by_filling_extra_space()
			}
			else {
				measure_children_bounds()
			}
		}

		var size = Stack_unit(total_spacing, 0)
		let bounds_across = fill_across ? bounds.across : 0
		for i in 0 ..< children.count {
			let item_size = children[i].measure_size(bounds_across)
			size.along += item_size.along
			size.across = max(size.across,  item_size.across)
		}

		if fill_along {
			size.along = bounds.along
		}
		if fill_across && size.across < bounds.across {
			size.across = bounds.across
		}

		var stack_origin = Stack_unit(layout_bounds.origin, in_horizontal_direction)

		switch stack.along {
			case .Center:
				stack_origin.along = stack_origin.along + bounds.along / 2 - (size.along + total_spacing) / 2
			case .Tailing:
				stack_origin.along = stack_origin.along + bounds.along - (size.along + total_spacing)
			default:
				break
		}


		for index in 0 ..< children.count {
			let child: Stack_child_measure = children[index]
			let child_bounds = Stack_unit(child.bounds_along, size.across)
			let child_bounds_frame = CGRect(origin: stack_origin.to_point(in_horizontal_direction), size: child_bounds.to_size(in_horizontal_direction))
			child.element.align(withSize: child.size.to_size(in_horizontal_direction), inBounds: child_bounds_frame)

			stack_origin.along += child_bounds.along + stack.spacing
			size.along += child_bounds.along
			size.across = max(size.across, child_bounds.across)
		}

		return CGRect(origin: layout_bounds.origin, size: size.to_size(in_horizontal_direction))
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
				along = try context.getEnum(attribute, UiAlignment.names)
			case "across":
				across = try context.getEnum(attribute, UiAlignment.names)
			case "spacing":
				spacing = try context.getFloat(attribute)
			default:
				try super.applyDeclarationAttribute(attribute, context: context)
		}
	}

}

