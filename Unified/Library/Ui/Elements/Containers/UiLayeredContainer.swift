//
// Created by Michael Vlasov on 07.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class UiLayeredContainer: UiMultipleElementContainer {

	// MARK: - UiElement

	public override func measureMaxSize(bounds: CGSize) -> CGSize {
		var maxSize = CGSizeZero
		for item in children {
			let itemSize = item.measureMaxSize(bounds)
			maxSize.width = max(maxSize.width, itemSize.width)
			maxSize.height = max(maxSize.height, itemSize.height)
		}
		return maxSize
	}

	public override func measureSize(bounds: CGSize) -> CGSize {
		var size = CGSizeZero
		for item in children {
			let itemSize = item.measureSize(bounds)
			size.width = max(size.width, itemSize.width)
			size.height = max(size.height, itemSize.height)
		}
		return size
	}

	public override func layout(bounds: CGRect) -> CGRect {
		for item in children {
			item.layout(bounds)
		}
		return bounds
	}

}



public class UiLayeredContainerFactory: UiElementFactory {

	override func create() -> UiElement {
		return UiLayeredContainer()
	}

	override func initialize(item: UiElement, content: [UiElement]) {
		super.initialize(item, content: content)
		let layered = item as! UiLayeredContainer
		layered.children = content
	}

}
