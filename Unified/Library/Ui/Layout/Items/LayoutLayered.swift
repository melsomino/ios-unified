//
// Created by Michael Vlasov on 07.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class LayoutLayered: LayoutWithMultipleContent {

	// MARK: - LayoutItem

	public override func measureMaxSize(bounds: CGSize) -> CGSize {
		var maxSize = CGSizeZero
		for item in content {
			let itemSize = item.measureMaxSize(bounds)
			maxSize.width = max(maxSize.width, itemSize.width)
			maxSize.height = max(maxSize.height, itemSize.height)
		}
		return maxSize
	}

	public override func measureSize(bounds: CGSize) -> CGSize {
		var size = CGSizeZero
		for item in content {
			let itemSize = item.measureSize(bounds)
			size.width = max(size.width, itemSize.width)
			size.height = max(size.height, itemSize.height)
		}
		return size
	}

	public override func layout(bounds: CGRect) -> CGRect {
		for item in content {
			item.layout(bounds)
		}
		return bounds
	}

}



