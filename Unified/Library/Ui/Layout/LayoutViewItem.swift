//
// Created by Власов М.Ю. on 03.06.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import UIKit

public class LayoutViewItem: LayoutFrameItem {

	public var hidden = false {
		didSet {
			boundView?.hidden = hidden
		}
	}

	public override var frame: CGRect {
		didSet {
			boundView?.frame = frame
		}
	}

	public var boundView: UIView? {
		return nil
	}


	// MARK: - LayoutItem


	public override var visible: Bool {
		return !hidden
	}

}
