//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class LayoutView<View: UIView>: LayoutViewItem {
	let size: CGSize
	let _fixedSize: Bool

	var view: View!
	var createView: ((CGRect) -> View)?

	public override var boundView: UIView? {
		return view
	}


	public init(size: CGSize, fixedSize: Bool, _ createView: ((CGRect) -> View)? = nil) {
		self.size = size
		self._fixedSize = fixedSize
		self.createView = createView
	}


	public convenience init(size: CGSize, _ createView: ((CGRect) -> View)? = nil) {
		self.init(size: size, fixedSize: true, createView)
	}


	// MARK: - LayoutItem


	public override func createViews(inSuperview superview: UIView) {
		if createView != nil {
			view = createView!(CGRectMake(0, 0, size.width, size.height))
			superview.addSubview(view!)
		}
	}


	public override var fixedSize: Bool {
		return _fixedSize
	}

	public override func measureMaxSize(bounds: CGSize) -> CGSize {
		return visible ? size : CGSizeZero
	}


	public override func measureSize(bounds: CGSize) -> CGSize {
		return visible ? size : CGSizeZero
	}


	public override func layout(bounds: CGRect) -> CGRect {
		if fixedSize {
			self.frame = CGRectMake(bounds.origin.x, bounds.origin.y, size.width, size.height)
		}
		else {
			self.frame = bounds
		}
		return frame
	}

}

