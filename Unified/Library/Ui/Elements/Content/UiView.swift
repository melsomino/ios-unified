//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class UiView: UiContentElement {
	var size = CGSizeZero
	public var fixedSizeValue = false

	var viewFactory: (() -> UIView)?

	public init(_ viewFactory: (() -> UIView)? = nil) {
		self.viewFactory = viewFactory
	}


	// MARK: - LayoutItem


	public override func createView() -> UIView {
		return viewFactory != nil ? viewFactory!() : super.createView()
	}


	public override var fixedSize: Bool {
		return fixedSizeValue
	}

	public override func measureMaxSize(bounds: CGSize) -> CGSize {
		return visible ? size : CGSizeZero
	}


	public override func measureSize(bounds: CGSize) -> CGSize {
		return visible ? size : CGSizeZero
	}


	public override func layout(bounds: CGRect) -> CGRect {
		if fixedSize {
			self.frame = CGRectMake(bounds.origin.x, bounds.origin.y, size.width, size.height)
		}
		else {
			self.frame = bounds
		}
		return frame
	}

}




class UiViewDefinition: UiContentElementDefinition {
	var size = CGSizeZero
	var fixedSize = false

	override func createElement() -> UiElement {
		return UiView()
	}

	override func initialize(element: UiElement, children: [UiElement]) {
		super.initialize(element, children: children)
		let view = element as! UiView
		view.size = size
		view.fixedSizeValue = fixedSize
	}

	override func applyDeclarationAttribute(attribute: DeclarationAttribute, context: DeclarationContext) throws {
		switch attribute.name {
			case "size":
				size = try context.getSize(attribute)
			case "fixed-size":
				fixedSize = try context.getBool(attribute)
			default:
				try super.applyDeclarationAttribute(attribute, context: context)
		}
	}

}





