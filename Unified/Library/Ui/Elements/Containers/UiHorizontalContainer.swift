//
// Created by Власов М.Ю. on 27.07.16.
//

import Foundation

public class UiHorizontalContainer: UiMultipleElementContainer {
	var spacing = CGFloat(0)

	public override func measureContent(inBounds bounds: CGSize) -> CGSize {
		var measure = Measure(container: self)
		measure.measure(inBounds: bounds)
		return measure.measured
	}


	public override func layoutContent(inBounds bounds: CGRect) {
		var measure = Measure(container: self)
		measure.layout(inBounds: bounds)
	}
}


private struct Child_measure {
	let element: UiElement
	var measured = CGSizeZero

	init(element: UiElement) {
		self.element = element
	}

	mutating func measure(inBounds bounds: CGSize) {
		measured = element.measure(inBounds: bounds)
	}
}

private struct Measure {
	let container: UiHorizontalContainer
	let total_spacing: CGFloat
	var children = [Child_measure]()
	var measured = CGSizeZero
	var measured_total_width = CGFloat(0)

	init(container: UiHorizontalContainer) {
		self.container = container
		for element in container.children {
			if element.visible {
				children.append(Child_measure(element: element))
			}
		}
		total_spacing = children.count > 1 ? container.spacing * CGFloat(children.count - 1) : 0
	}

	mutating func measure(inBounds bounds: CGSize) {
		measured = CGSizeZero
		measured_total_width = total_spacing
		let bounds_without_spacing = CGSizeMake(bounds.width - total_spacing, bounds.height)
		for i in 0 ..< children.count {
			children[i].measure(inBounds: bounds_without_spacing)
			let child_measured = children[i].measured
			measured.height = max(measured.height, child_measured.height)
			measured_total_width += child_measured.width
		}

		measured.width = min(measured_total_width, bounds.width)
	}

	mutating func layout(inBounds bounds: CGRect) {
		measure(inBounds: bounds.size)

		if measured_total_width <= bounds.width {
			layout_when_total_width_more_than_bounds_width()
		}
		else {
			layout_when_total_width_more_than_bounds_width()
		}
	}

	mutating func layout_when_total_width_more_than_bounds_width() {
		let y = bounds.origin.y
		var x = bounds.origin.x
		for child in children {
			let child_bounds = CGRectMake(x, y, child.measured.width, measured.height)
			child.element.layout(inBounds: child_bounds, usingMeasured: child.measured)
			x += child.measured.width + container.spacing
		}
	}

	mutating func layout_when_total_width_less_than_bounds_width() {
		let y = bounds.origin.y
		var x = bounds.origin.x
		for child in children {
			let child_bounds = CGRectMake(x, y, child.measured.width, measured.height)
			child.element.layout(inBounds: child_bounds, usingMeasured: child.measured)
			x += child.measured.width + container.spacing
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

