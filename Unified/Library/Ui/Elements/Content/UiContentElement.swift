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




class UiContentElementFactory: UiElementFactory {
	var backgroundColor: UIColor?
	var cornerRadius: CGFloat?

	override func applyDeclarationAttribute(attribute: DeclarationAttribute, context: DeclarationContext) throws {
		switch attribute.name {
			case "background":
				backgroundColor = try context.getColor(attribute)
			case "corner-radius":
				cornerRadius = try context.getFloat(attribute)
			default:
				try super.applyDeclarationAttribute(attribute, context: context)
		}
	}

	override func initialize(item: UiElement, content: [UiElement]) {
		super.initialize(item, content: content)
		let viewItem = item as! UiContentElement
		viewItem.backgroundColor = backgroundColor
		viewItem.cornerRadius = cornerRadius
	}

}





