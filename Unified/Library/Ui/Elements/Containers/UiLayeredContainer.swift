//
// Created by Michael Vlasov on 07.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class UiLayeredContainer: UiMultipleElementContainer {

	// MARK: - UiElement

	public override func measureContent(inBounds bounds: CGSize) -> CGSize {
		var measure = Measure(elements: children)
		measure.measure(inBounds: bounds)
		return measure.measured
	}


	public override func layoutContent(inBounds bounds: CGRect) {
		var measure = Measure(elements: children)
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
	var children = [Child_measure]()
	var measured = CGSizeZero

	init(elements: [UiElement]) {
		for element in elements {
			if element.visible {
				children.append(Child_measure(element: element))
			}
		}
	}

	mutating func measure(inBounds bounds: CGSize) {
		measured = CGSizeZero
		for i in 0 ..< children.count {
			children[i].measure(inBounds: bounds)
			let child_measured = children[i].measured
			measured.width = max(measured.width, child_measured.width)
			measured.height = max(measured.height, child_measured.height)
		}
		if measured.width > bounds.width {
			measured.width = bounds.width
		}
	}

	mutating func layout(inBounds bounds: CGRect) {
		measure(inBounds: bounds.size)
		for child in children {
			child.element.layout(inBounds: bounds, usingMeasured: child.measured)
		}
	}
}

public class UiLayeredContainerDefinition: UiElementDefinition {

	public override func createElement() -> UiElement {
		return UiLayeredContainer()
	}

	public override func initialize(element: UiElement, children: [UiElement]) {
		super.initialize(element, children: children)
		let layered = element as! UiLayeredContainer
		layered.children = children
	}

}
