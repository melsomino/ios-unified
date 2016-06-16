//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit


enum LayoutAlignment {
	case Fill, Leading, Tailing, Center
}




public class Layout {

	public let boundToViews: Bool
	public private(set) var root: LayoutItem
	public private(set) var frameItems: [LayoutFrameItem]
	public var frame = CGRectZero

	private var _root: LayoutItem!

	public required init(inSuperview superview: UIView?) {
		self.boundToViews = superview != nil
		root = LayoutItem()
		frameItems = [LayoutFrameItem]()
		root = createRoot()
		root.collectFrameItems(&frameItems)
		if boundToViews {
			root.createViews(inSuperview: superview!)
			initViews()
		}
	}





	public func performLayoutInBounds(bounds: CGRect) {
		root.measureMaxSize(bounds.size)
		root.measureSize(bounds.size)
		frame = root.layout(bounds)
	}





	public func performLayoutForWidth(width: CGFloat) {
		performLayoutInBounds(CGRectMake(0, 0, width, LayoutItem.maxHeight))
	}





	public func performLayoutForWidth(width: CGFloat, cache: LayoutCache, key: String) {
		if let frames = cache.cachedFramesForWidth(width, key: key) {
			frame = frames[0]
			for index in 0 ..< min(frames.count - 1, frameItems.count) {
				frameItems[index].frame = frames[index + 1]
			}
			return
		}

		performLayoutForWidth(width)

		var frames = [CGRect](count: 1 + frameItems.count, repeatedValue: CGRectZero)
		frames[0] = frame
		for index in 0 ..< frameItems.count {
			frames[index + 1] = frameItems[index].frame
		}
		cache.setFrames(frames, forWidth: width, key: key)
	}


	// MARK: - Virtuals


	public func createRoot() -> LayoutItem {
		return LayoutItem()
	}


	public func initViews() {
	}


	// MARK: - Layouts


	func padding(top top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat, _ content: LayoutItem) -> LayoutPadding {
		return LayoutPadding(top: top, left: left, bottom: bottom, right: right, content)
	}

	func padding(top top: CGFloat, _ content: LayoutItem) -> LayoutPadding {
		return LayoutPadding(top: top, left: 0, bottom: 0, right: 0, content)
	}

	func padding(all: CGFloat, _ content: LayoutItem) -> LayoutPadding {
		return LayoutPadding(top: all, left: all, bottom: all, right: all, content)
	}

	func padding(horizontal horizontal: CGFloat, vertical: CGFloat, _ content: LayoutItem) -> LayoutPadding {
		return LayoutPadding(top: vertical, left: horizontal, bottom: vertical, right: horizontal, content)
	}

	func layered(content: LayoutItem...) -> LayoutLayered {
		return LayoutLayered(content)
	}

	func aligned(anchor: LayoutAlignAnchor, _ content: LayoutItem) -> LayoutAlign {
		return LayoutAlign(anchor: anchor, content)
	}

	func horizontal(along along: LayoutAlignment, across: LayoutAlignment, spacing: CGFloat, _ content: LayoutItem...) -> LayoutItem {
		return LayoutStack(direction: .Horizontal, along: along, across: across, spacing: spacing, content)
	}

	func horizontal(content: LayoutItem...) -> LayoutItem {
		return LayoutStack(direction: .Horizontal, along: .Fill, across: .Leading, spacing: 0, content)
	}

	func horizontal(spacing spacing: CGFloat, _ content: LayoutItem...) -> LayoutItem {
		return LayoutStack(direction: .Horizontal, along: .Fill, across: .Leading, spacing: spacing, content)
	}

	func horizontal(along along: LayoutAlignment, _ content: LayoutItem...) -> LayoutItem {
		return LayoutStack(direction: .Horizontal, along: along, across: .Leading, spacing: 0, content)
	}

	func vertical(along along: LayoutAlignment, across: LayoutAlignment, spacing: CGFloat, _ content: LayoutItem...) -> LayoutItem {
		return LayoutStack(direction: .Vertical, along: along, across: across, spacing: spacing, content)
	}

	func vertical(along along: LayoutAlignment, spacing: CGFloat, _ content: LayoutItem...) -> LayoutItem {
		return LayoutStack(direction: .Vertical, along: along, across: .Leading, spacing: spacing, content)
	}

	func vertical(content: LayoutItem...) -> LayoutItem {
		return LayoutStack(direction: .Vertical, along: .Leading, across: .Leading, spacing: 0, content)
	}

	func vertical(spacing spacing: CGFloat, _ content: LayoutItem...) -> LayoutItem {
		return LayoutStack(direction: .Vertical, along: .Leading, across: .Leading, spacing: spacing, content)
	}

	func vertical(along along: LayoutAlignment, _ content: LayoutItem...) -> LayoutItem {
		return LayoutStack(direction: .Vertical, along: along, across: .Leading, spacing: 0, content)
	}

}







