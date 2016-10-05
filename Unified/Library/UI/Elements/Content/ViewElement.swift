//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

open class ViewElement: ContentElement {
	open var width: CGFloat?
	open var height: CGFloat?

	var viewFactory: (() -> UIView)?

	public init(_ viewFactory: (() -> UIView)? = nil) {
		self.viewFactory = viewFactory
	}


	// MARK: - LayoutItem


	open override func createView() -> UIView {
		return viewFactory != nil ? viewFactory!() : super.createView()
	}


	open override func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		if let width = width {
			return SizeMeasure(width: width, height: height ?? 0)
		}
		return SizeMeasure(width: (0, bounds.width), height: height ?? 0)
	}


	open override func layoutContent(inBounds bounds: CGRect) {
		var size = bounds.size
		if let width = width {
			size.width = min(size.width, width)
		}
		if let height = height {
			size.height = min(size.height, height)
		}
		frame = CGRect(origin: bounds.origin, size: size)
	}

}




open class ViewElementDefinition: ContentElementDefinition {
	open var width: CGFloat?
	open var height: CGFloat?

	open override func createElement() -> FragmentElement {
		return ViewElement()
	}

	open override func initialize(_ element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)
		let view = element as! ViewElement
		view.width = width
		view.height = height
	}

	open override func applyDeclarationAttribute(_ attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
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
				try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
		}
	}

}





