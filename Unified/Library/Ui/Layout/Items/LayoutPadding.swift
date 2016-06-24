//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

class LayoutPadding: LayoutWithSingleContent {
	var insets = UIEdgeInsetsZero


	// MARK: - LayoutItem


	override func measureMaxSize(bounds: CGSize) -> CGSize {
		return expandSize(content.measureMaxSize(reduceSize(bounds)))
	}

	override func measureSize(bounds: CGSize) -> CGSize {
		return expandSize(content.measureSize(reduceSize(bounds)))
	}

	override func layout(bounds: CGRect) -> CGRect {
		return expandRect(content.layout(UIEdgeInsetsInsetRect(bounds, insets)))
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



