//
// Created by Власов М.Ю. on 27.07.16.
//

import Foundation





open class VerticalContainer: MultipleElementContainer {
	var spacing = CGFloat(0)

	open override func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		var measure = Vertical_measure(container: self)
		return measure.measure(in_bounds: bounds)
	}



	open override func layoutContent(inBounds bounds: CGRect) {
		var measure = Vertical_measure(container: self)
		measure.layout(in_bounds: bounds)
	}
}





private struct Vertical_measure {





	private struct Element_measure {
		let element: FragmentElement
		var measured = SizeMeasure.zero

		init(element: FragmentElement) {
			self.element = element
		}



		mutating func measure(in_bounds bounds: CGSize) -> SizeMeasure {
			measured = element.measure(inBounds: bounds)
			return measured
		}
	}





	let container: VerticalContainer
	let total_spacing: CGFloat
	var children = [Element_measure]()
	var measured = SizeMeasure.zero

	init(container: VerticalContainer) {
		self.container = container
		for element in container.children {
			if element.visible {
				children.append(Element_measure(element: element))
			}
		}
		total_spacing = children.count > 1 ? container.spacing * CGFloat(children.count - 1) : 0
	}



	mutating func measure(in_bounds bounds: CGSize) -> SizeMeasure {
		measured = SizeMeasure(width: 0, height: total_spacing)

		for i in 0 ..< children.count {
			let child = children[i].measure(in_bounds: CGSize(width: bounds.width, height: 0))
			measured.width.min = max(measured.width.min, child.width.min)
			measured.width.max = max(measured.width.max, child.width.max)
			measured.height += child.height
		}
		return measured
	}



	mutating func layout(in_bounds bounds: CGRect) {
		measure(in_bounds: bounds.size)
		var y = bounds.origin.y
		let x = bounds.origin.x
		for child in children {
			let child_bounds = CGRect(x: x, y: y, width: bounds.width, height: child.measured.height)
			child.element.layout(inBounds: child_bounds, usingMeasured: child.measured.maxSize)
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



	override func initialize(_ element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)
		let vertical = element as! VerticalContainer
		vertical.children = children
		vertical.spacing = spacing
	}



	override func applyDeclarationAttribute(_ attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		switch attribute.name {
			case "spacing":
				spacing = try context.getFloat(attribute)
			default:
				try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
		}
	}

}

