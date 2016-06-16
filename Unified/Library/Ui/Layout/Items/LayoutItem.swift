//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit


public class LayoutItem {
	public static let maxHeight = CGFloat(9000)

	public var visible: Bool {
		return true
	}

	public var fixedSize: Bool {
		return false
	}

	public func createViews(inSuperview superview: UIView) {

	}

	public func collectFrameItems(inout items: [LayoutFrameItem]) {

	}

	public func measureMaxSize(bounds: CGSize) -> CGSize {
		return bounds
	}

	public func measureSize(bounds: CGSize) -> CGSize {
		return bounds
	}

	public func layout(bounds: CGRect) -> CGRect {
		return bounds
	}



}
