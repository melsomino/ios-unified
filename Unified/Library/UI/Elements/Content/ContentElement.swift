//
// Created by Michael Vlasov on 03.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

open class ContentElement: FragmentElement {

	open var view: UIView!

	open var hidden = false {
		didSet {
			view?.isHidden = hidden
		}
	}

	open var frame: CGRect = CGRect.zero {
		didSet {
			view?.frame = frame
		}
	}

	open var backgroundColor: UIColor? {
		didSet {
			initializeView()
		}
	}

	open var cornerRadius: CGFloat? {
		didSet {
			initializeView()
		}
	}

	open var borderWidth: CGFloat? {
		didSet {
			initializeView()
		}
	}

	open var borderColor: UIColor? {
		didSet {
			initializeView()
		}
	}

	open var corners = UIRectCorner.allCorners {
		didSet {
			initializeView()
		}
	}

	open var defaultBackgroundColor: UIColor?

	public override init() {
		super.init()
	}


	// MARK: - Virtuals


	open func createView() -> UIView {
		return UIView()
	}

	open func onViewCreated() {
		defaultBackgroundColor = view.backgroundColor
	}

	open func initializeView() {
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
		view.layer.borderWidth = borderWidth ?? 0
		view.layer.borderColor = (borderColor ?? UIColor.clear).cgColor
	}


	// MARK: - UiElement


	open override var visible: Bool {
		return !hidden
	}

	open override func layoutContent(inBounds bounds: CGRect) {
		frame = bounds
	}


	open override func bind(toModel values: [Any?]) {
		super.bind(toModel: values)
		if let boundHidden = definition.boundHidden(values) {
			hidden = boundHidden
		}
	}

	// MARK: - Internals

	var cornersLayer: CAShapeLayer?
}




open class ContentElementDefinition: FragmentElementDefinition {
	open var backgroundColor: UIColor?
	open var cornerRadius: CGFloat?
	open var corners = UIRectCorner.allCorners
	open var borderWidth: CGFloat?
	open var borderColor: UIColor?


	open override func applyDeclarationAttribute(_ attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		switch attribute.name {
			case "background-color":
				backgroundColor = try context.getColor(attribute)
			case "corner-radius":
				cornerRadius = try context.getFloat(attribute)
			case "border-width":
				borderWidth = try context.getFloat(attribute)
			case "border-color":
				borderColor = try context.getColor(attribute)
			default:
				try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
		}
	}

	private func applyCornerRadius(_ attribute: DeclarationAttribute, value: DeclarationValue, context: DeclarationContext) throws {
		switch value {
			case .value(let string):
				var size: Float = 0
				if Scanner(string: string).scanFloat(&size) {
					cornerRadius = CGFloat(size)
				}
				else {
					guard let corner = ContentElementDefinition.cornerByName[string] else {
						throw DeclarationError("Invalid corner radius value", attribute, context)
					}
					corners = corners.union(corner)
				}
			case .list(let values):
				for value in values {
					try applyCornerRadius(attribute, value: value, context: context)
				}
			default:
				throw DeclarationError("Invalid corner radius attribute", attribute, context)
		}
	}

	static let cornerByName: [String: UIRectCorner] = [
		"top-left": .topLeft,
		"left-top": .topLeft,
		"top-right": .topRight,
		"right-top": .topRight,
		"bottom-left": .bottomLeft,
		"left-bottom": .bottomLeft,
		"bottom-right": .bottomRight,
		"right-bottom": .bottomRight,
		"top": [.topLeft, .topRight],
		"bottom": [.bottomLeft, .bottomRight],
		"left": [.topLeft, .bottomLeft],
		"right": [.topRight, .bottomRight]
	]


	open override func initialize(_ element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)
		let contentElement = element as! ContentElement
		contentElement.backgroundColor = backgroundColor
		contentElement.cornerRadius = cornerRadius
		contentElement.borderWidth = borderWidth
		contentElement.borderColor = borderColor
	}

}





