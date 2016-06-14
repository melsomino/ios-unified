//
// Created by Власов М.Ю. on 03.06.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import UIKit

public class LayoutFrameItem: LayoutItem {
	var frame = CGRectZero

	public override func collectFrameItems(inout items: [LayoutFrameItem]) {
		items.append(self)
	}

	public override func layout(bounds: CGRect) -> CGRect {
		frame = bounds
		return frame
	}

}
