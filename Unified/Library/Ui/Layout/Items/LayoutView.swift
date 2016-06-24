//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class LayoutView: LayoutViewItem {
	var size = CGSizeZero
	public var fixedSizeValue = false

	var viewFactory: (() -> UIView)?

	public init(_ viewFactory: (() -> UIView)? = nil) {
		self.viewFactory = viewFactory
	}


	// MARK: - LayoutItem


	public override func createView() -> UIView {
		return viewFactory != nil ? viewFactory!() : super.createView()
	}


	public override var fixedSize: Bool {
		return fixedSizeValue
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

