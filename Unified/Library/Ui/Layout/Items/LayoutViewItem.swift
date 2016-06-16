//
// Created by Michael Vlasov on 03.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class LayoutViewItem: LayoutFrameItem {

	var initView: ((UIView) -> Void)?

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
