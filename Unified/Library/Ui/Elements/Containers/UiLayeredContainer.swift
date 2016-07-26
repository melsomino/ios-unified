//
// Created by Michael Vlasov on 07.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class UiLayeredContainer: UiMultipleElementContainer {

	// MARK: - UiElement

	public override func measureContent(inBounds bounds: CGSize) -> SizeRange {
		var range = SizeRange.zero
		for element in children {
			let itemSizeRange = element.measure(inBounds: bounds)
			range.min.width = max(range.min.width, itemSizeRange.min.width)
			range.min.height = max(range.min.height, itemSizeRange.min.height)
			range.max.width = max(range.max.width, itemSizeRange.max.width)
			range.max.height = max(range.max.height, itemSizeRange.max.height)
		}
		return range
	}


	public override func layoutContent(inBounds bounds: CGRect) -> CGRect {
		for child in children {
			let childSizeRange = child.measure(inBounds: bounds.size)
			child.align(withSize: childSizeRange.max, inBounds: bounds)
		}
		return bounds
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
