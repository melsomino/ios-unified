//
// Created by Власов М.Ю. on 27.07.16.
//

import Foundation

public class UiHorizontalContainer: UiMultipleElementContainer {
	var spacing = CGFloat(0)

	public override func measureContent(inBounds bounds: CGSize) -> CGSize {
		var measure = Horizontal_measure(container: self)
		measure.measure(in_bounds: bounds)
		return measure.measured
	}


	public override func layoutContent(inBounds bounds: CGRect) {
		var measure = Horizontal_measure(container: self)
		measure.layout(in_bounds: bounds)
	}
}





private struct Horizontal_child_measure {
	let element: UiElement
	var measured_first_pass = CGSizeZero
	var measured = CGSizeZero

	init(element: UiElement) {
		self.element = element
	}

	mutating func measure_first_pass(in_bounds bounds: CGSize) {
		measured_first_pass = element.measure(in_bounds: bounds)
		measured = measured_first_pass
	}

	mutating func measure_second_pass(in_bounds bounds: CGSize) {
		measured = element.measure(in_bounds: bounds)
	}
}





private struct Horizontal_measure {
	let container: UiHorizontalContainer
	let total_spacing: CGFloat
	var children = [Horizontal_child_measure]()
	var measured = CGSizeZero
	var measured_total_width = CGFloat(0)
	var min_width_without_spacing = CGFloat(0)

	init(container: UiHorizontalContainer) {
		self.container = container
		for element in container.children {
			if element.visible {
				children.append(Horizontal_child_measure(element: element))
			}
		}
		total_spacing = children.count > 1 ? container.spacing * CGFloat(children.count - 1) : 0
	}

	mutating func measure(in_bounds bounds: CGSize) {
		measure_first_pass(in_bounds: bounds)
		if measured_total_width <= bounds.width {
			return
		}

		measure_second_pass(in_bounds: bounds)
		if measured_total_width <= bounds.width {
			return
		}

		measure_third_pass(in_bounds: bounds)
	}


	mutating func measure_first_pass(in_bounds bounds: CGSize) {
		measured = CGSizeZero
		measured_total_width = total_spacing
		let bounds_without_spacing = CGSizeMake(10000 - total_spacing, bounds.height)
		for i in 0 ..< children.count {
			children[i].measure_first_pass(in_bounds: bounds_without_spacing)
			let child_measured = children[i].measured
			measured.height = max(measured.height, child_measured.height)
			measured_total_width += child_measured.width
		}

		if container.horizontalAlignment == .fill || measured_total_width > bounds.width {
			measured.width = bounds.width
		}
		else {
			measured.width = measured_total_width
		}
	}


	mutating func measure_second_pass(in_bounds bounds: CGSize) {
		let first_pass_total_width = measured_total_width
		measured = CGSizeZero
		let bounds_without_spacing = bounds.width - total_spacing
		measured_total_width = total_spacing
		let width_ratio = bounds_without_spacing / (first_pass_total_width - total_spacing)
		min_width_without_spacing = total_spacing
		for i in 0 ..< children.count {
			let child_bounds = CGSizeMake(children[i].measured.width*width_ratio, bounds.height)
			children[i].measure_second_pass(in_bounds: child_bounds)
			let child_measured = children[i].measured
			if child_measured.width >= children[i].measured_first_pass.width {
				min_width_without_spacing += child_measured.width
			}
			measured.height = max(measured.height, child_measured.height)
			measured_total_width += child_measured.width
		}

		if measured_total_width <= bounds.width && min_width_without_spacing > 0 {
			let flexible_width = measured_total_width - total_spacing - min_width_without_spacing
			if flexible_width > 0 {
				let width_ratio = (bounds_without_spacing - min_width_without_spacing) / flexible_width
				measured_total_width = total_spacing
				for i in 0 ..< children.count {
					let child_bounds = CGSizeMake(children[i].measured.width * width_ratio, bounds.height)
					children[i].measure_second_pass(in_bounds: child_bounds)
					let child_measured = children[i].measured
					measured.height = max(measured.height, child_measured.height)
					measured_total_width += child_measured.width
				}
			}
		}

		measured.width = bounds.width
	}



	mutating func measure_third_pass(in_bounds bounds: CGSize) {
		let second_pass_total_width = measured_total_width
		measured = CGSizeZero
		let bounds_without_spacing = bounds.width - total_spacing
		let flexible_width = second_pass_total_width - total_spacing - min_width_without_spacing
		var width_ratio: CGFloat
		if flexible_width <= 0 {
			width_ratio = 0
		}
		else if bounds_without_spacing - min_width_without_spacing < 0 {
			width_ratio = 0
		} else {
			width_ratio = (bounds_without_spacing - min_width_without_spacing) / flexible_width
		}
		measured_total_width = total_spacing
		for i in 0 ..< children.count {
			var child_measured = children[i].measured
			if child_measured.width < children[i].measured_first_pass.width {
				let child_bounds = CGSizeMake(children[i].measured.width * width_ratio, bounds.height)
				if child_bounds.width <= 0 {
					children[i].measured = child_bounds
				}
				else {
					children[i].measure_second_pass(in_bounds: child_bounds)
				}
				child_measured = children[i].measured
			}
			measured.height = max(measured.height, child_measured.height)
			measured_total_width += child_measured.width
		}

		measured.width = container.horizontalAlignment == .fill ? bounds.width : measured_total_width
	}



	mutating func layout(in_bounds bounds: CGRect) {
		measure(in_bounds: bounds.size)

		let y = bounds.origin.y
		var x = bounds.origin.x
		if container.horizontalAlignment == .fill && measured_total_width < bounds.width {
			let width_ratio = (bounds.width - total_spacing)/(measured_total_width - total_spacing)
			for child in children {
				let child_bounds = CGRectMake(x, y, child.measured.width*width_ratio, measured.height)
				child.element.layout(inBounds: child_bounds, usingMeasured: child.measured)
				x += child_bounds.width + container.spacing
			}
		}
		else {
			for child in children {
				let child_bounds = CGRectMake(x, y, child.measured.width, measured.height)
				child.element.layout(inBounds: child_bounds, usingMeasured: child.measured)
				x += child.measured.width + container.spacing
			}
		}
	}
}


class UiHorizontalContainerDefinition: UiElementDefinition {

	var spacing = CGFloat(0)

	override func createElement() -> UiElement {
		return UiHorizontalContainer()
	}


	override func initialize(element: UiElement, children: [UiElement]) {
		super.initialize(element, children: children)
		let horizontal = element as! UiHorizontalContainer
		horizontal.children = children
		horizontal.spacing = spacing
	}


	override func applyDeclarationAttribute(attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		switch attribute.name {
			case "spacing":
				spacing = try context.getFloat(attribute)
			default:
				try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
		}
	}

}

