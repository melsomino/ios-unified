//
// Created by Michael Vlasov on 03.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class LayoutViewItem: LayoutItem {

	public var view: UIView! {
		didSet {
		}
	}

	public var hidden = false {
		didSet {
			view?.hidden = hidden
		}
	}

	public var frame: CGRect = CGRectZero {
		didSet {
			view?.frame = frame
		}
	}

	public var backgroundColor: UIColor? {
		didSet {
			initializeView()
		}
	}

	public var cornerRadius: CGFloat? {
		didSet {
			initializeView()
		}
	}

	// MARK: - Virtuals


	public func createView() -> UIView {
		return UIView()
	}


	public func initializeView() {
		guard let view = view else {
			return
		}

		if let color = backgroundColor {
			view.backgroundColor = color
		}
		else {
			view.backgroundColor = UIColor.clearColor()
		}

		if let radius = cornerRadius {
			view.clipsToBounds = true
			view.layer.cornerRadius = radius
		}
		else {
			view.layer.cornerRadius = 0
		}
	}


	// MARK: - LayoutItem


	public override var visible: Bool {
		return !hidden
	}

	public override func layout(bounds: CGRect) -> CGRect {
		frame = bounds
		return frame
	}

}
