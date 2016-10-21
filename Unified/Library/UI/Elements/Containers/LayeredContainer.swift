//
// Created by Michael Vlasov on 07.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit





open class LayeredContainer: MultipleElementContainer {


	// MARK: - FragmentElement

	open override func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		var measure = Layered_measure(elements: children)
		return measure.measure(in_bounds: bounds)
	}



	open override func layoutContent(inBounds bounds: CGRect) {
		var measure = Layered_measure(elements: children)
		measure.layout(in_bounds: bounds)
	}

}





private struct Layered_measure {





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





	var children = [Element_measure]()
	var measured = SizeMeasure.zero

	init(elements: [FragmentElement]) {
		for element in elements {
			if element.includeInLayout {
				children.append(Element_measure(element: element))
			}
		}
	}



	mutating func measure(in_bounds bounds: CGSize) -> SizeMeasure {
		measured = SizeMeasure.zero
		for i in 0 ..< children.count {
			let child = children[i].measure(in_bounds: bounds)
			measured.width.min = max(measured.width.min, child.width.min)
			measured.width.max = max(measured.width.max, child.width.max)
			measured.height = max(measured.height, child.height)
		}
		return measured
	}



	mutating func layout(in_bounds bounds: CGRect) {
		let _ = measure(in_bounds: bounds.size)
		for child in children {
			child.element.layout(inBounds: bounds, usingMeasured: child.measured.maxSize)
		}
	}
}





open class LayeredContainerDefinition: FragmentElementDefinition {

	open override func createElement() -> FragmentElement {
		return LayeredContainer()
	}



	open override func initialize(_ element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)
		let layered = element as! LayeredContainer
		layered.children = children
	}

}
