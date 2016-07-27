//
// Created by Власов М.Ю. on 27.07.16.
//

import Foundation

public class UiVerticalContainer: UiMultipleElementContainer {
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
	let container: UiVerticalContainer
	let total_spacing: CGFloat
	var children = [Child_measure]()
	var measured = CGSizeZero

	init(container: UiVerticalContainer) {
		self.container = container
		for element in container.children {
			if element.visible {
				children.append(Child_measure(element: element))
			}
		}
		total_spacing = children.count > 1 ? container.spacing * CGFloat(children.count - 1) : 0
	}

	mutating func measure(inBounds bounds: CGSize) {
		measured = CGSizeMake(0, total_spacing)
		for i in 0 ..< children.count {
			children[i].measure(inBounds: bounds)
			let child_measured = children[i].measured
			measured.width = max(measured.width, child_measured.width)
			measured.height += child_measured.height
		}
		if measured.width > bounds.width {
			measured.width = bounds.width
		}
	}

	mutating func layout(inBounds bounds: CGRect) {
		measure(inBounds: bounds.size)
		var y = bounds.origin.y
		let x = bounds.origin.x
		for child in children {
			let child_bounds = CGRectMake(x, y, bounds.width, child.measured.height)
			child.element.layout(inBounds: child_bounds, usingMeasured: child.measured)
			y += child.measured.height + container.spacing
		}
	}
}


class UiVerticalContainerDefinition: UiElementDefinition {

	var spacing = CGFloat(0)

	override func createElement() -> UiElement {
		return UiVerticalContainer()
	}


	override func initialize(element: UiElement, children: [UiElement]) {
		super.initialize(element, children: children)
		let vertical = element as! UiVerticalContainer
		vertical.children = children
		vertical.spacing = spacing
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

