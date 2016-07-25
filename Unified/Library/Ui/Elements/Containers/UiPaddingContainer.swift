//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

class UiPaddingContainer: UiSingleElementContainer {
	var insets = UIEdgeInsetsZero


	// MARK: - UiElement


	override func measure(inBounds bounds: CGSize) -> SizeRange {
		let childRange = child.measure(inBounds: reduceSize(bounds))
		return SizeRange(min: expandSize(childRange.min), max: expandSize(childRange.max))
	}

	override func layout(inBounds bounds: CGRect) -> CGRect {
		return expandRect(child.layout(inBounds: UIEdgeInsetsInsetRect(bounds, insets)))
	}


	// MARK: - Internals


	private func reduceSize(size: CGSize) -> CGSize {
		return CGSizeMake(size.width - insets.left - insets.right, size.height - insets.top - insets.bottom)
	}

	private func expandSize(size: CGSize) -> CGSize {
		return CGSizeMake(size.width + insets.left + insets.right, size.height + insets.top + insets.bottom)
	}

	private func expandRect(rect: CGRect) -> CGRect {
		return CGRectMake(rect.origin.x - insets.left, rect.origin.y - insets.top, rect.size.width + insets.left + insets.right, rect.size.height + insets.top + insets.bottom)
	}

}



class UiPaddingContainerDefinition: UiElementDefinition {
	var insets = UIEdgeInsetsZero

	override func createElement() -> UiElement {
		return UiPaddingContainer()
	}

	override func initialize(element: UiElement, children: [UiElement]) {
		super.initialize(element, children: children)
		let element = element as! UiPaddingContainer
		element.insets = insets
		element.child = children[0]
	}
}





