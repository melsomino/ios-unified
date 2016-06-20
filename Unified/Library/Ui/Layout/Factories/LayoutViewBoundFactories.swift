//
// Created by Власов М.Ю. on 16.06.16.
// Copyright (c) 2016 melsomino. All rights reserved.
//

import Foundation
import UIKit


class LayoutViewBoundFactory: LayoutItemFactory {
	var backgroundColor: UIColor?
	var cornerRadius: CGFloat?

	override func applyDeclarationAttribute(attribute: DeclarationAttribute) throws {
		switch attribute.name {
			case "background":
				backgroundColor = try attribute.value.getColor()
			case "cornerradius", "corner-radius":
				cornerRadius = try attribute.value.getFloat()
			default:
				try super.applyDeclarationAttribute(attribute)
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
	var fixedSize = false

	override func create() -> LayoutItem {
		return LayoutView(size: size, fixedSize: fixedSize, { frame in UIView() })
	}

	override func apply(item: LayoutItem, _ content: [LayoutItem]) {
		super.apply(item, content)
		let view = item as! LayoutView
		view.size = size
		view._fixedSize = fixedSize
	}

	override func applyDeclarationAttribute(attribute: DeclarationAttribute) throws {
		try super.applyDeclarationAttribute(attribute)
		switch attribute.name {
			case "size":
				size = try attribute.value.getSize()
			case "fixedsize", "fixed-size":
				fixedSize = try attribute.value.getBool()
			default:
				try super.applyDeclarationAttribute(attribute)
		}
	}

}





