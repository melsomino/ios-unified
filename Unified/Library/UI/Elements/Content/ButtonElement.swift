//
// Created by Michael Vlasov on 28.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit



public class ButtonElement: ContentElement {

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

		button.contentEdgeInsets = padding
		button.imageEdgeInsets = imageMargin
		button.titleEdgeInsets = titleMargin
		button.setImage(image, forState: .Normal)
		button.setTitle(title, forState: .Normal)
		button.tintColor = color
	}


	// MARK: - UiElement


	public override func createView() -> UIView {
		return UIButton()
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
		return CGSizeMake(20, 20)
	}



	// MARK: - Internals



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


	// MARK: - UiElementDefinition


	public override func applyDeclarationAttribute(attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		switch attribute.name {
			case "font":
//				try applyFontValue(attribute, value: attribute.value, context: context)
				break
			case "color":
				color = try context.getColor(attribute)
			case "title":
				title = try context.getExpression(attribute)
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
	}


	// MARK: - Internals


}




