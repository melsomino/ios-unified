//
// Created by Michael Vlasov on 07.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class UiLayeredContainer: UiMultipleElementContainer {

	// MARK: - UiElement

	public override func measureSizeRange(inBounds bounds: CGSize) -> SizeRange {
		var range = SizeRange.zero
		for element in children {
			let itemRange = element.measureSizeRange(inBounds: bounds)
			range.min.width = max(range.min.width, itemRange.min.width)
			range.min.height = max(range.min.height, itemRange.min.height)
			range.max.width = max(range.max.width, itemRange.max.width)
			range.max.height = max(range.max.height, itemRange.max.height)
		}
		return range
	}


	public override func measureSize(inBounds bounds: CGSize) -> CGSize {
		var size = CGSizeZero
		for item in children {
			let itemSize = item.measureSize(inBounds: bounds)
			size.width = max(size.width, itemSize.width)
			size.height = max(size.height, itemSize.height)
		}
		return size
	}

	public override func layout(inBounds bounds: CGRect) -> CGRect {
		for item in children {
			item.layout(inBounds: bounds)
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
