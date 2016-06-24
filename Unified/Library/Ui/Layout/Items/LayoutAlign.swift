//
// Created by Michael Vlasov on 07.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public enum LayoutAlignAnchor {
	case TopLeft, Top, TopRight, Right, BottomRight, Bottom, BottomLeft, Left, Center
}

public class LayoutAlign: LayoutWithSingleContent {
	var anchor = LayoutAlignAnchor.TopLeft


	public override func measureMaxSize(bounds: CGSize) -> CGSize {
		return content.measureMaxSize(bounds)
	}

	public override func measureSize(bounds: CGSize) -> CGSize {
		contentSize = content.measureSize(bounds)
		return contentSize
	}

	public override func layout(bounds: CGRect) -> CGRect {
		var contentOrigin = CGPointZero
		switch anchor {
			case .TopLeft, .Left, .BottomLeft:
				contentOrigin.x = bounds.origin.x
				break
			case .TopRight, .Right, .BottomRight:
				contentOrigin.x = bounds.origin.x + bounds.size.width - contentSize.width
				break
			default:
				contentOrigin.x = bounds.origin.x + bounds.size.width / 2 - contentSize.width / 2
		}
		switch anchor {
			case .TopLeft, .Top, .TopRight:
				contentOrigin.y = bounds.origin.y
				break
			case .BottomLeft, .Bottom, .BottomRight:
				contentOrigin.y = bounds.origin.y + bounds.size.height - contentSize.height
				break
			default:
				contentOrigin.y = bounds.origin.y + bounds.size.height / 2 - contentSize.height / 2
		}

		content.layout(CGRectMake(contentOrigin.x, contentOrigin.y, contentSize.width, contentSize.height))
		return bounds
	}


	// MARK: - Internals


	private var contentSize = CGSizeZero

}





