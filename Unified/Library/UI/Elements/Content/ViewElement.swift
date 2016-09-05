//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class ViewElement: ContentElement {
	public var width: CGFloat?
	public var height: CGFloat?

	var viewFactory: (() -> UIView)?

	public init(_ viewFactory: (() -> UIView)? = nil) {
		self.viewFactory = viewFactory
	}


	// MARK: - LayoutItem


	public override func createView() -> UIView {
		return viewFactory != nil ? viewFactory!() : super.createView()
	}


	public override func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		if let width = width {
			return SizeMeasure(width: width, height: height ?? 0)
		}
		return SizeMeasure(width: (0, bounds.width), height: height ?? 0)
	}


	public override func layoutContent(inBounds bounds: CGRect) {
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




public class ViewElementDefinition: ContentElementDefinition {
	public var width: CGFloat?
	public var height: CGFloat?

	public override func createElement() -> FragmentElement {
		return ViewElement()
	}

	public override func initialize(element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)
		let view = element as! ViewElement
		view.width = width
		view.height = height
	}

	public override func applyDeclarationAttribute(attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
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





