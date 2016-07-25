//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class UiView: UiContentElement {
	var width: CGFloat?
	var height: CGFloat?

	var viewFactory: (() -> UIView)?

	public init(_ viewFactory: (() -> UIView)? = nil) {
		self.viewFactory = viewFactory
	}


	// MARK: - LayoutItem


	public override func createView() -> UIView {
		return viewFactory != nil ? viewFactory!() : super.createView()
	}


	public override func measureSizeRange(inBounds bounds: CGSize) -> SizeRange {
		guard visible else {
			return SizeRange.zero
		}
		var range = SizeRange(min: CGSizeZero, max: bounds)
		if let width = width {
			range.min.width = width
			range.max.width = width
		}
		if let height = height {
			range.min.height = height
			range.max.height = height
		}
		return range
	}


	public override func measureSize(inBounds bounds: CGSize) -> CGSize {
		guard visible else {
			return CGSizeZero
		}
		var size = bounds
		if let width = width {
			size.width = width
		}
		if let height = height {
			size.height = height
		}
		return size
	}


	public override func layout(inBounds bounds: CGRect) -> CGRect {
		self.frame = CGRect(origin: bounds.origin, size: measureSize(inBounds: bounds.size))
		return frame
	}

}




public class UiViewDefinition: UiContentElementDefinition {
	public var width: CGFloat?
	public var height: CGFloat?

	public override func createElement() -> UiElement {
		return UiView()
	}

	public override func initialize(element: UiElement, children: [UiElement]) {
		super.initialize(element, children: children)
		let view = element as! UiView
		view.width = width
		view.height = height
	}

	public override func applyDeclarationAttribute(attribute: DeclarationAttribute, context: DeclarationContext) throws {
		switch attribute.name {
			case "width":
				width = try context.getFloat(attribute)
			case "height":
				height = try context.getFloat(attribute)
			case "size":
				let size = try context.getSize(attribute)
				width = size.width
				height = size.height
			default:
				try super.applyDeclarationAttribute(attribute, context: context)
		}
	}

}





