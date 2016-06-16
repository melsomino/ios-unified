//
// Created by Власов М.Ю. on 16.06.16.
// Copyright (c) 2016 melsomino. All rights reserved.
//

import Foundation
import UIKit


class LayoutViewBoundFactory: LayoutItemFactory {
	var backgroundColor: UIColor?
	var cornerRadius: CGFloat?

	override func applyMarkupAttributeWithName(name: String, value: MarkupValue) throws {
		switch name {
			case "background":
				backgroundColor = try value.getColor()
			case "cornerradius":
				cornerRadius = try value.getFloat()
			default:
				try super.applyMarkupAttributeWithName(name, value: value)
		}
	}

	override func apply(item: LayoutItem, _ content: [LayoutItem]) {
		super.apply(item, content)
		let viewItem = item as! LayoutViewItem

		if backgroundColor != nil || cornerRadius != nil {
			let bc = backgroundColor
			let cr = cornerRadius
			viewItem.initView = {
				view in
				if bc != nil {
					view.backgroundColor = bc!
				}
				if cr != nil {
					view.clipsToBounds = true
					view.layer.cornerRadius = cr!
				}
			}
		}
	}

}





class LayoutViewFactory: LayoutViewBoundFactory {
	var size = CGSizeZero
	var fixedSize = true

	override func create() -> LayoutItem {
		return LayoutView(size: size, fixedSize: fixedSize, { frame in UIView() })
	}

	override func apply(item: LayoutItem, _ content: [LayoutItem]) {
		super.apply(item, content)
		let view = item as! LayoutView
		view.size = size
		view._fixedSize = fixedSize
	}

	override func applyMarkupAttributeWithName(name: String, value: MarkupValue) throws {
		try super.applyMarkupAttributeWithName(name, value: value)
		switch name {
			case "size":
				size = try value.getSize()
			case "fixedsize":
				fixedSize = try value.getBool()
			default:
				try super.applyMarkupAttributeWithName(name, value: value)
		}
	}

}





