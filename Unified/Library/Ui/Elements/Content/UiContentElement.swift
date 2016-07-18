//
// Created by Michael Vlasov on 03.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class UiContentElement: UiElement {

	public var view: UIView!

	public var hidden = false {
		didSet {
			view?.hidden = hidden
		}
	}

	public var frame: CGRect = CGRectZero {
		didSet {
			view?.frame = frame
		}
	}

	public var backgroundColor: UIColor? {
		didSet {
			initializeView()
		}
	}

	public var cornerRadius: CGFloat? {
		didSet {
			initializeView()
		}
	}

	public override init() {
		super.init()
	}


	// MARK: - Virtuals


	public func createView() -> UIView {
		return UIView()
	}

	public func onViewCreated() {
		defaultBackgroundColor = view.backgroundColor
	}

	public func initializeView() {
		guard let view = view else {
			return
		}

		view.backgroundColor = backgroundColor ?? defaultBackgroundColor

		if let radius = cornerRadius {
			view.clipsToBounds = true
			view.layer.cornerRadius = radius
		}
		else {
			view.layer.cornerRadius = 0
		}
	}


	// MARK: - UiElement


	public override var visible: Bool {
		return !hidden
	}

	public override func layout(bounds: CGRect) -> CGRect {
		frame = bounds
		return frame
	}

	// MARK: - Internals

	private var defaultBackgroundColor: UIColor?

}




public class UiContentElementDefinition: UiElementDefinition {
	public var backgroundColor: UIColor?
	public var cornerRadius: CGFloat?


	public override func applyDeclarationAttribute(attribute: DeclarationAttribute, context: DeclarationContext) throws {
		switch attribute.name {
			case "background-color":
				backgroundColor = try context.getColor(attribute)
			case "corner-radius":
				cornerRadius = try context.getFloat(attribute)
			default:
				try super.applyDeclarationAttribute(attribute, context: context)
		}
	}

	public override func initialize(element: UiElement, children: [UiElement]) {
		super.initialize(element, children: children)
		let contentElement = element as! UiContentElement
		contentElement.backgroundColor = backgroundColor
		contentElement.cornerRadius = cornerRadius
	}

}





