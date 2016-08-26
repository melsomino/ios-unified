//
// Created by Michael Vlasov on 28.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore



public class ButtonElement: ContentElement {

	class ActionDelegate: NSObject {
		weak var element: ButtonElement?
		func onTouchUpInside() {
			element?.onTouchUpInside()
		}
	}

	public var buttonDefinition: ButtonElementDefinition {
		return definition as! ButtonElementDefinition
	}

	public var font: UIFont? {
		didSet {
			initializeView()
		}
	}

	public var padding = UIEdgeInsetsZero {
		didSet {
			initializeView()
		}
	}

	public var imageMargin = UIEdgeInsetsZero {
		didSet {
			initializeView()
		}
	}

	public var titleMargin = UIEdgeInsetsZero {
		didSet {
			initializeView()
		}
	}

	public var color: UIColor? {
		didSet {
			(view as? UIButton)?.tintColor = color
		}
	}

	public var title: String? {
		didSet {
			if let button = view as? UIButton {
				button.setTitle(title, forState: .Normal)
			}
		}
	}


	public var image: UIImage? {
		didSet {
			if let button = view as? UIButton {
				button.setImage(image, forState: .Normal)
			}
		}
	}


	public override required init() {
		super.init()
	}


	// MARK: - ContentElement


	public override func initializeView() {
		guard let view = view else {
			return
		}

		view.layer.backgroundColor = backgroundColor?.CGColor
		if let radius = cornerRadius {
			view.clipsToBounds = true
			view.layer.cornerRadius = radius
		}
		else {
			view.layer.cornerRadius = 0
		}

		guard let button = view as? UIButton else {
			return
		}

//		button.contentEdgeInsets = padding
//		button.imageEdgeInsets = imageMargin
//		button.titleEdgeInsets = titleMargin
		button.setImage(image, forState: .Normal)
		button.setTitle(title, forState: .Normal)
		button.tintColor = color
		button.titleLabel?.font = font
	}


	// MARK: - FragmentElement


	public override func createView() -> UIView {
		let button = UIButton(type: .System)
		actionDelegate.element = self
		button.addTarget(actionDelegate, action: #selector(ActionDelegate.onTouchUpInside), forControlEvents: .TouchUpInside)
		return button
	}

	func onTouchUpInside() {
		if let action = (definition as? ButtonElementDefinition)?.action, delegate = delegate {
			delegate.tryExecuteAction(action)
		}
	}

	public override func bind(toModel values: [Any?]) {
		super.bind(toModel: values)
		if let titleBinding = buttonDefinition.title {
			title = titleBinding.evaluate(values)
		}
	}


	public override var visible: Bool {
		return !hidden
	}



	public override func measureContent(inBounds bounds: CGSize) -> CGSize {
		guard visible else {
			return CGSizeZero
		}
		return CGSizeMake(25, 25)
	}


	public override func layoutContent(inBounds bounds: CGRect) {
		super.layoutContent(inBounds: bounds)
	}


	// MARK: - Internals

	var actionDelegate = ActionDelegate()

}




class DefaultButtonMetrics {
	let font: UIFont
	let padding: UIEdgeInsets
	let imageMargin: UIEdgeInsets
	let titleMargin: UIEdgeInsets

	init() {
		let button = UIButton(type: .Custom)
		padding = button.contentEdgeInsets
		imageMargin = button.imageEdgeInsets
		titleMargin = button.titleEdgeInsets
		font = button.titleLabel?.font ?? UIFont.systemFontOfSize(UIFont.systemFontSize())
	}

	static let metrics = DefaultButtonMetrics()
}





public class ButtonElementDefinition: ContentElementDefinition {
	var font = DefaultButtonMetrics.metrics.font
	var padding = DefaultButtonMetrics.metrics.padding
	var imageMargin = DefaultButtonMetrics.metrics.imageMargin
	var titleMargin = DefaultButtonMetrics.metrics.titleMargin
	var color: UIColor?
	var image: UIImage?
	var title: DynamicBindings.Expression?
	var action: DynamicBindings.Expression?


	// MARK: - UiElementDefinition


	public override func applyDeclarationAttribute(attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		switch attribute.name {
			case "font":
				try applyFontValue(attribute, value: attribute.value, context: context)
			case "color":
				color = try context.getColor(attribute)
			case "title":
				title = try context.getExpression(attribute)
			case "action":
				action = try context.getExpression(attribute)
			case "image":
				image = try context.getImage(attribute)
			default:
				if try applyInsets(&padding, name: "padding", attribute: attribute, context: context) {
				}
				else if try applyInsets(&imageMargin, name: "image-margin", attribute: attribute, context: context) {
				}
				else if try applyInsets(&titleMargin, name: "title-margin", attribute: attribute, context: context) {
				}
				else {
					try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
				}
		}
	}



	private func applyFontValue(attribute: DeclarationAttribute, value: DeclarationValue, context: DeclarationContext) throws {
		switch value {
			case .value(let string):
				var size: Float = 0
				if string == "bold" {
					font = UIFont(descriptor: font.fontDescriptor().fontDescriptorWithSymbolicTraits(UIFontDescriptorSymbolicTraits.TraitBold), size: font.pointSize)
				}
				else if NSScanner(string: string).scanFloat(&size) {
					font = font.fontWithSize(CGFloat(size))
				}
				else {
					font = UIFont(name: string, size: font.pointSize) ?? font
				}
			case .list(let values):
				for value in values {
					try applyFontValue(attribute, value: value, context: context)
				}
			default:
				throw DeclarationError("Font attributes expected", attribute, context)
		}
	}


	private func applyInsets(inout insets: UIEdgeInsets, name: String, attribute: DeclarationAttribute, context: DeclarationContext) throws -> Bool {
		if name == "padding" {
			insets = try context.getInsets(attribute)
		}
		else if name == "\(name)-top" {
			insets.top = try context.getFloat(attribute)
		}
		else if name == "\(name)-bottom" {
			insets.bottom = try context.getFloat(attribute)
		}
		else if name == "\(name)-left" {
			insets.left = try context.getFloat(attribute)
		}
		else if name == "\(name)-right" {
			insets.right = try context.getFloat(attribute)
		}
		else {
			return false
		}
		return true
	}




	public override func createElement() -> FragmentElement {
		return ButtonElement()
	}



	public override func initialize(element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)

		let button = element as! ButtonElement
		button.image = image
		button.color = color
		button.font = font
	}


	// MARK: - Internals


}




