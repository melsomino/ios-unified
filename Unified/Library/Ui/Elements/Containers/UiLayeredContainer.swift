//
// Created by Michael Vlasov on 07.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class UiLayeredContainer: UiMultipleElementContainer {

	// MARK: - UiElement

	public override func measureContent(inBounds bounds: CGSize) -> CGSize {
		var measure = Layered_measure(elements: children)
		measure.measure(in_bounds: bounds)
		return measure.measured
	}


	public override func layoutContent(inBounds bounds: CGRect) {
		var measure = Layered_measure(elements: children)
		measure.layout(in_bounds: bounds)
	}

}

private struct Layered_child_measure {
	let element: UiElement
	var measured = CGSizeZero

	init(element: UiElement) {
		self.element = element
	}

	mutating func measure(in_bounds bounds: CGSize) {
		measured = element.measure(inBounds: bounds)
	}
}

private struct Layered_measure {
	var children = [Layered_child_measure]()
	var measured = CGSizeZero

	init(elements: [UiElement]) {
		for element in elements {
			if element.visible {
				children.append(Layered_child_measure(element: element))
			}
		}
	}

	mutating func measure(in_bounds bounds: CGSize) {
		measured = CGSizeZero
		for i in 0 ..< children.count {
			children[i].measure(in_bounds: bounds)
			let child_measured = children[i].measured
			measured.width = max(measured.width, child_measured.width)
			measured.height = max(measured.height, child_measured.height)
		}
		if measured.width > bounds.width {
			measured.width = bounds.width
		}
	}

	mutating func layout(in_bounds bounds: CGRect) {
		measure(in_bounds: bounds.size)
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
