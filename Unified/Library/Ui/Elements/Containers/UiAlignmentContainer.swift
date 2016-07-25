//
// Created by Michael Vlasov on 07.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public enum UiAlignmentAnchor {
	case TopLeft, Top, TopRight, Right, BottomRight, Bottom, BottomLeft, Left, Center
}

public class UiAlignmentContainer: UiSingleElementContainer {
	var anchor = UiAlignmentAnchor.TopLeft


	public override func measure(inBounds bounds: CGSize) -> SizeRange {
		return child.measure(inBounds: bounds)
	}

	public override func layout(inBounds bounds: CGRect) -> CGRect {
		let childSize = child.measure(inBounds: bounds.size).max
		var contentOrigin = CGPointZero
		switch anchor {
			case .TopLeft, .Left, .BottomLeft:
				contentOrigin.x = bounds.origin.x
				break
			case .TopRight, .Right, .BottomRight:
				contentOrigin.x = bounds.origin.x + bounds.size.width - childSize.width
				break
			default:
				contentOrigin.x = bounds.origin.x + bounds.size.width / 2 - childSize.width / 2
		}
		switch anchor {
			case .TopLeft, .Top, .TopRight:
				contentOrigin.y = bounds.origin.y
				break
			case .BottomLeft, .Bottom, .BottomRight:
				contentOrigin.y = bounds.origin.y + bounds.size.height - childSize.height
				break
			default:
				contentOrigin.y = bounds.origin.y + bounds.size.height / 2 - childSize.height / 2
		}

		child.layout(inBounds: CGRect(origin: contentOrigin, size: childSize))
		return bounds
	}

}





public class UiAlignmentContainerFactory: UiElementDefinition {
	var anchor = UiAlignmentAnchor.TopLeft

	public override func createElement() -> UiElement {
		return UiAlignmentContainer()
	}

	public override func initialize(element: UiElement, children: [UiElement]) {
		super.initialize(element, children: children)
		let align = element as! UiAlignmentContainer
		align.anchor = anchor
		align.child = children[0]
	}
}





