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
		super.initializeView()

		guard let button = view as? UIButton else {
			return
		}

		button.setImage(image, forState: .Normal)
		button.setTitle(title, forState: .Normal)
		if type == .Custom {
			button.setTitleColor(color, forState: .Normal)
		}
		else {
			button.tintColor = color
		}
		button.titleLabel?.font = font
		button.contentEdgeInsets = padding
	}


	// MARK: - FragmentElement


	public override func createView() -> UIView {
		let button = UIButton(type: type)
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
		if let boundHidden = definition.boundHidden(values) {
			hidden = boundHidden
		}
	}


	public override var visible: Bool {
		return !hidden
	}


	public override func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		let imageSize = image?.size ?? CGSizeZero
		let titleSize = TextElement.measureText(title, font: font, padding: UIEdgeInsetsZero, inWidth: CGFloat.max)
		let spacing = CGFloat(0)
		let measured = SizeMeasure(width: imageSize.width + spacing + titleSize.width, height: max(imageSize.height, titleSize.height))
		return FragmentElement.expand(measure: measured, edges: padding)
	}


	public override func layoutContent(inBounds bounds: CGRect) {
		super.layoutContent(inBounds: bounds)
	}


	// MARK: - Internals

	var type = UIButtonType.System
	var actionDelegate = ActionDelegate()
}





class DefaultButtonMetrics {
	let font: UIFont
	let padding: UIEdgeInsets
	let imageMargin: UIEdgeInsets
	let titleMargin: UIEdgeInsets

	init(type: UIButtonType) {
		let button = UIButton(type: type)
		padding = button.contentEdgeInsets
		imageMargin = button.imageEdgeInsets
		titleMargin = button.titleEdgeInsets
		font = button.titleLabel?.font ?? UIFont.systemFontOfSize(UIFont.systemFontSize())
	}


	static func from(type: UIButtonType) -> DefaultButtonMetrics {
		return type == .Custom ? custom : system
	}

	static let system = DefaultButtonMetrics(type: .System)
	static let custom = DefaultButtonMetrics(type: .Custom)
}





public class ButtonElementDefinition: ContentElementDefinition {
	var font = DefaultButtonMetrics.system.font
	var padding = DefaultButtonMetrics.system.padding
	var imageMargin = DefaultButtonMetrics.system.imageMargin
	var titleMargin = DefaultButtonMetrics.system.titleMargin
	var type = UIButtonType.System
	var color: UIColor?
	var image: UIImage?
	var title: DynamicBindings.Expression?
	var action: DynamicBindings.Expression?


	// MARK: - UiElementDefinition


	public override func applyDeclarationAttribute(attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		switch attribute.name {
			case "type":
				type = try context.getEnum(attribute, ButtonElementDefinition.typesByName)
			case "font":
				font = try context.getFont(attribute, defaultFont: font)
			case "color":
				color = try context.getColor(attribute)
			case "title":
				title = try context.getExpression(attribute)
			case "action":
				action = try context.getExpression(attribute)
			case "image":
				image = try context.getImage(attribute)
			default:
				if try context.applyInsets(&padding, name: "padding", attribute: attribute) {
				}
				else if try context.applyInsets(&imageMargin, name: "image-margin", attribute: attribute) {
				}
				else if try context.applyInsets(&titleMargin, name: "title-margin", attribute: attribute) {
				}
				else {
					try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
				}
		}
	}


	public override func createElement() -> FragmentElement {
		return ButtonElement()
	}


	public override func initialize(element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)

		let button = element as! ButtonElement
		button.type = type
		button.image = image
		button.color = color
		button.font = font
		button.padding = padding
	}


	// MARK: - Internals

	static let typesByName: [String:UIButtonType] = [
		"system": .System,
		"custom": .Custom
	]

}




