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
			guard let view = view else {
				return
			}
			view.frame = frame
			updateShadow()
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

	public var shadowOpacity = CGFloat(0) {
		didSet {
			initializeView()
		}
	}
	public var shadowRadius = CGFloat(3) {
		didSet {
			initializeView()
		}
	}
	public var shadowOffset = CGSize(width: 0, height: 3) {
		didSet {
			initializeView()
		}
	}
	public var shadowColor = UIColor.black.cgColor {
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

		let layer = view.layer
		layer.backgroundColor = (backgroundColor ?? defaultBackgroundColor ?? UIColor.clear).cgColor

		if let radius = cornerRadius, radius > 0 {
			if shadowOpacity == 0 {
				view.clipsToBounds = true
			}
			layer.cornerRadius = radius
		}
		else {
			layer.cornerRadius = 0
		}
		layer.borderWidth = borderWidth ?? 0
		layer.borderColor = (borderColor ?? UIColor.clear).cgColor
		layer.shadowOpacity = Float(shadowOpacity)
		layer.shadowRadius = shadowRadius
		layer.shadowOffset = shadowOffset
		layer.shadowColor = shadowColor
		updateShadow()
	}


	// MARK: - FragmentElement


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

	private func updateShadow() {
		guard let view = view, let definition = definition as? ContentElementDefinition, definition.hasShadow else {
			return
		}
		let radius = cornerRadius ?? 0
		let shadow = radius > 0
			? UIBezierPath(roundedRect: view.bounds, cornerRadius: radius)
			: UIBezierPath(rect: view.bounds)
		view.layer.shadowPath = shadow.cgPath
	}
}




open class ContentElementDefinition: FragmentElementDefinition {
	open var backgroundColor: UIColor?
	open var cornerRadius: CGFloat?
	open var corners = UIRectCorner.allCorners
	open var borderWidth: CGFloat?
	open var borderColor: UIColor?

	public var hasShadow = false
	public var shadowOpacity = CGFloat(0)
	public var shadowRadius = CGFloat(3)
	public var shadowOffset = CGSize(width: 0, height: 3)
	public var shadowColor = UIColor.black.cgColor

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
			case "shadow-opacity":
				shadowOpacity = try context.getFloat(attribute)
				hasShadow = true
			case "shadow-radius":
				shadowRadius = try context.getFloat(attribute)
				hasShadow = true
			case "shadow-offset":
				shadowOffset = try context.getSize(attribute)
				hasShadow = true
			case "shadow-color":
				shadowColor = try context.getColor(attribute).cgColor
				hasShadow = true
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
					try applyCornerRadius(attribute, value: .value(value), context: context)
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
		contentElement.shadowOpacity = shadowOpacity
		contentElement.shadowRadius = shadowRadius
		contentElement.shadowOffset = shadowOffset
		contentElement.shadowColor = shadowColor
	}

}





