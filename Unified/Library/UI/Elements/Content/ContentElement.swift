//
// Created by Michael Vlasov on 03.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

public class ContentElement: FragmentElement {

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

	public var borderWidth: CGFloat? {
		didSet {
			initializeView()
		}
	}

	public var borderColor: UIColor? {
		didSet {
			initializeView()
		}
	}

	public var corners = UIRectCorner.AllCorners {
		didSet {
			initializeView()
		}
	}

	public var defaultBackgroundColor: UIColor?

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
		view.layer.borderWidth = borderWidth ?? 0
		view.layer.borderColor = (borderColor ?? UIColor.clearColor()).CGColor
	}


	// MARK: - UiElement


	public override var visible: Bool {
		return !hidden
	}

	public override func layoutContent(inBounds bounds: CGRect) {
		frame = bounds
	}


	public override func bind(toModel values: [Any?]) {
		super.bind(toModel: values)
		if let boundHidden = definition.boundHidden(values) {
			hidden = boundHidden
		}
	}

	// MARK: - Internals

	var cornersLayer: CAShapeLayer?
}




public class ContentElementDefinition: FragmentElementDefinition {
	public var backgroundColor: UIColor?
	public var cornerRadius: CGFloat?
	public var corners = UIRectCorner.AllCorners
	public var borderWidth: CGFloat?
	public var borderColor: UIColor?


	public override func applyDeclarationAttribute(attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
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

	private func applyCornerRadius(attribute: DeclarationAttribute, value: DeclarationValue, context: DeclarationContext) throws {
		switch value {
			case .value(let string):
				var size: Float = 0
				if NSScanner(string: string).scanFloat(&size) {
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
		"top-left": .TopLeft,
		"left-top": .TopLeft,
		"top-right": .TopRight,
		"right-top": .TopRight,
		"bottom-left": .BottomLeft,
		"left-bottom": .BottomLeft,
		"bottom-right": .BottomRight,
		"right-bottom": .BottomRight,
		"top": [.TopLeft, .TopRight],
		"bottom": [.BottomLeft, .BottomRight],
		"left": [.TopLeft, .BottomLeft],
		"right": [.TopRight, .BottomRight]
	]


	public override func initialize(element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)
		let contentElement = element as! ContentElement
		contentElement.backgroundColor = backgroundColor
		contentElement.cornerRadius = cornerRadius
		contentElement.borderWidth = borderWidth
		contentElement.borderColor = borderColor
	}

}





