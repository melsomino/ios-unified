//
// Created by Власов М.Ю. on 27.07.16.
//

import Foundation

public class VerticalContainer: MultipleElementContainer {
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
	let element: FragmentElement
	var measured = CGSizeZero

	init(element: FragmentElement) {
		self.element = element
	}

	mutating func measure(inBounds bounds: CGSize) {
		measured = element.measure(inBounds: bounds)
	}
}

private struct Vertical_measure {
	let container: VerticalContainer
	let total_spacing: CGFloat
	var children = [Vertical_child_measure]()
	var measured = CGSizeZero

	init(container: VerticalContainer) {
		self.container = container
		for element in container.children {
			if element.visible {
				children.append(Vertical_child_measure(element: element))
			}
		}
		total_spacing = children.count > 1 ? container.spacing * CGFloat(children.count - 1) : 0
	}

	mutating private func measure(in_width width: CGFloat) {
		measured = CGSizeMake(0, total_spacing)

		for i in 0 ..< children.count {
			children[i].measure(inBounds: CGSizeMake(width, 0))
			let child_measured = children[i].measured
			measured.width = max(measured.width, child_measured.width)
			measured.height += child_measured.height
		}
	}

	mutating func measure(in_bounds bounds: CGSize) {
		if container.horizontalAlignment == .fill {
			measure(in_width: bounds.width)
			measured.width = bounds.width
		}
		else {
			measure(in_width: 10000)
			if measured.width > bounds.width {
				measure(in_width: bounds.width)
			}
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


class VerticalContainerDefinition: FragmentElementDefinition {

	var spacing = CGFloat(0)

	override init() {
		super.init()
		horizontalAlignment = .fill
	}

	override func createElement() -> FragmentElement {
		return VerticalContainer()
	}


	override func initialize(element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)
		let vertical = element as! VerticalContainer
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

