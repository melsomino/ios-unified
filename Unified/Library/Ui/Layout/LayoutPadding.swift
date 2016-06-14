//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

class LayoutPadding: LayoutItem {
	let insets: UIEdgeInsets
	let content: LayoutItem

	init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat, _ content: LayoutItem) {
		self.insets = UIEdgeInsetsMake(top, left, bottom, right)
		self.content = content
	}

	override var visible: Bool {
		return content.visible
	}

	override var fixedSize: Bool {
		return content.fixedSize
	}

	override func createViews(inSuperview superview: UIView) {
		content.createViews(inSuperview: superview)
	}


	override func collectFrameItems(inout items: [LayoutFrameItem]) {
		content.collectFrameItems(&items)
	}

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



