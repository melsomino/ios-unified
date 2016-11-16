//
// Created by Michael Vlasov on 28.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore





open class ButtonElement: ContentElement {





	class ActionDelegate: NSObject {
		weak var element: ButtonElement?
		func onTouchUpInside() {
			element?.onTouchUpInside()
		}
	}





	open var buttonDefinition: ButtonElementDefinition {
		return definition as! ButtonElementDefinition
	}

	open var font: UIFont? {
		didSet {
			initializeView()
		}
	}

	open var padding = UIEdgeInsets.zero {
		didSet {
			initializeView()
		}
	}

	open var imageMargin = UIEdgeInsets.zero {
		didSet {
			initializeView()
		}
	}

	open var titleMargin = UIEdgeInsets.zero {
		didSet {
			initializeView()
		}
	}

	open var color: UIColor? {
		didSet {
			(view as? UIButton)?.tintColor = color
		}
	}

	open var title: String? {
		didSet {
			if let button = view as? UIButton {
				button.setTitle(title, for: UIControlState())
			}
		}
	}


	open var lineBreak: NSLineBreakMode = .byTruncatingMiddle {
		didSet {
			if let button = view as? UIButton {
				button.titleLabel?.lineBreakMode = lineBreak
			}
		}
	}

	open var image: UIImage? {
		didSet {
			if let button = view as? UIButton {
				button.setImage(image, for: UIControlState())
			}
		}
	}


	public override required init() {
		super.init()
	}


	// MARK: - ContentElement


	open override func initializeView() {
		super.initializeView()

		guard let button = view as? UIButton else {
			return
		}

		button.setImage(image, for: UIControlState())
		button.setTitle(title, for: UIControlState())
		if type == .custom {
			button.setTitleColor(color, for: UIControlState())
		}
		else {
			button.tintColor = color
		}
		if let label = button.titleLabel {
			label.lineBreakMode = lineBreak
			label.font = font
		}
		button.contentEdgeInsets = padding
	}


	// MARK: - FragmentElement


	open override func createView() -> UIView {
		let button = UIButton(type: type)
		actionDelegate.element = self
		button.addTarget(actionDelegate, action: #selector(ActionDelegate.onTouchUpInside), for: .touchUpInside)
		return button
	}


	func onTouchUpInside() {
		if let action = (definition as? ButtonElementDefinition)?.action, let delegate = delegate {
			delegate.tryExecuteAction(action, defaultArgs: nil)
		}
	}


	open override func bind(toModel values: [Any?]) {
		super.bind(toModel: values)
		if let titleBinding = buttonDefinition.title {
			title = titleBinding.evaluate(values)
		}
		if let boundHidden = definition.boundHidden(values) {
			hidden = boundHidden
		}
	}


	open override var visible: Bool {
		return !hidden
	}


	open override func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		let imageSize = image?.size ?? CGSize.zero
		var titleSize: SizeMeasure

		switch lineBreak {
			case .byWordWrapping, .byCharWrapping:
				let size = TextElement.measureText(title, font: font, inWidth: bounds.width - imageSize.width - padding.left + padding.right)
				titleSize = SizeMeasure(width: (CGFloat(5), size.width), height: size.height)
			default:
				let size = TextElement.measureText(title, font: font, inWidth: CGFloat.greatestFiniteMagnitude)
				titleSize = SizeMeasure(width: size.width, height: size.height)
		}
		let spacing = CGFloat(0)
		let measured = SizeMeasure(
			width: (imageSize.width + spacing + titleSize.width.min, imageSize.width + spacing + titleSize.width.max),
			height: max(imageSize.height, titleSize.height))
		return FragmentElement.expand(measure: measured, edges: padding)
	}


	open override func layoutContent(inBounds bounds: CGRect) {
		super.layoutContent(inBounds: bounds)
	}


	// MARK: - Internals

	var type = UIButtonType.system
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
		font = button.titleLabel?.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
	}


	static func from(_ type: UIButtonType) -> DefaultButtonMetrics {
		return type == .custom ? custom : system
	}

	static let system = DefaultButtonMetrics(type: .system)
	static let custom = DefaultButtonMetrics(type: .custom)
}





open class ButtonElementDefinition: ContentElementDefinition {
	var font = DefaultButtonMetrics.system.font
	var padding = DefaultButtonMetrics.system.padding
	var imageMargin = DefaultButtonMetrics.system.imageMargin
	var titleMargin = DefaultButtonMetrics.system.titleMargin
	var type = UIButtonType.system
	var color: UIColor?
	var image: UIImage?
	var title: DynamicBindings.Expression?
	var action: DynamicBindings.Expression?
	var lineBreak = NSLineBreakMode.byTruncatingMiddle


	// MARK: - UiElementDefinition


	open override func applyDeclarationAttribute(_ attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
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
			case "line-break":
				lineBreak = try context.getEnum(attribute, ButtonElementDefinition.lineBreakByName)
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


	open override func createElement() -> FragmentElement {
		return ButtonElement()
	}


	open override func initialize(_ element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)

		guard let element = element as? ButtonElement else {
			return
		}
		element.type = type
		element.image = image
		element.color = color
		element.font = font
		element.padding = padding
		element.lineBreak = lineBreak
	}


	// MARK: - Internals

	static let lineBreakByName: [String: NSLineBreakMode] = [
		"word-wrap": .byWordWrapping,
		"char-wrap": .byCharWrapping,
		"clip": .byClipping,
		"truncate-head": .byTruncatingHead,
		"truncate-tail": .byTruncatingTail,
		"truncate-middle": .byTruncatingMiddle
	]

	static let typesByName: [String:UIButtonType] = [
		"system": .system,
		"custom": .custom
	]

}




