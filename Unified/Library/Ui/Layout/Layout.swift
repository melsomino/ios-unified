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

	public private(set) var boundToViews: Bool
	public private(set) var root: LayoutItem
	public private(set) var frameItems: [LayoutViewItem]
	public var frame = CGRectZero

	private var _root: LayoutItem!

	public required init(inSuperview superview: UIView?) {
		self.boundToViews = superview != nil
		root = LayoutItem()
		frameItems = [LayoutViewItem]()
		recreate(inSuperview: superview)
	}


	public func recreate(inSuperview superview: UIView?) {
		if boundToViews {
			for item in frameItems {
				item.view?.removeFromSuperview()
			}
		}
		frameItems.removeAll(keepCapacity: true)
		root = createRoot()
		root.traversal {
			if let view = $0 as? LayoutViewItem {
				frameItems.append(view)
			}
		}
		boundToViews = superview != nil
		if boundToViews {
			for item in frameItems {
				if item.view == nil {
					item.view = item.createView()
				}
				superview!.addSubview(item.view!)
			}
			initViews()
		}
	}


	public func performLayoutInBounds(bounds: CGRect) {
		root.measureMaxSize(bounds.size)
		root.measureSize(bounds.size)
		frame = root.layout(bounds)
	}





	public func performLayoutForWidth(width: CGFloat) {
		performLayoutInBounds(CGRectMake(0, 0, width, 9000))
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


}







