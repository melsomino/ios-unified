//
// Created by Власов М.Ю. on 27.07.16.
//

import Foundation

public class UiVerticalContainer: UiMultipleElementContainer {
	var spacing = CGFloat(0)

	public override func measureContent(inBounds bounds: CGSize) -> CGSize {
		var measure = Vertical_measure(container: self)
		measure.measure(in_bounds: bounds)
		return measure.measured
	}


	public override func layoutContent(inBounds bounds: CGRect) {
		var measure = Vertical_measure(container: self)
		measure.layout(in_bounds: bounds)
	}
}


private struct Vertical_child_measure {
	let element: UiElement
	var measured = CGSizeZero

	init(element: UiElement) {
		self.element = element
	}

	mutating func measure(inBounds bounds: CGSize) {
		measured = element.measure(in_bounds: bounds)
	}
}

private struct Vertical_measure {
	let container: UiVerticalContainer
	let total_spacing: CGFloat
	var children = [Vertical_child_measure]()
	var measured = CGSizeZero

	init(container: UiVerticalContainer) {
		self.container = container
		for element in container.children {
			if element.visible {
				children.append(Vertical_child_measure(element: element))
			}
		}
		total_spacing = children.count > 1 ? container.spacing * CGFloat(children.count - 1) : 0
	}

	mutating func measure(in_bounds bounds: CGSize) {
		measured = CGSizeMake(0, total_spacing)
		for i in 0 ..< children.count {
			children[i].measure(inBounds: CGSizeMake(10000, 0))
			let child_measured = children[i].measured
			measured.width = max(measured.width, child_measured.width)
			measured.height += child_measured.height
		}
		if measured.width > bounds.width || container.horizontalAlignment == .fill {
			measured = CGSizeMake(0, total_spacing)
			for i in 0 ..< children.count {
				children[i].measure(inBounds: CGSizeMake(bounds.width, 0))
				let child_measured = children[i].measured
				measured.height += child_measured.height
			}

			measured.width = bounds.width
		}
	}

	mutating func layout(in_bounds bounds: CGRect) {
		measure(in_bounds: bounds.size)
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

	override init() {
		super.init()
		horizontalAlignment = .fill
	}

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

