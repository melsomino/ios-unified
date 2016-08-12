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
		button.imageEdgeInsets = imagePadding
		button.titleEdgeInsets = titlePadding
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
		return measureTextSize(inBounds: bounds)
	}



	// MARK: - Internals


	private func textForMeasure() -> String {
		return text ?? ""
	}


	private func measureTextSize(inBounds bounds: CGSize) -> CGSize {
		guard visible else {
			return CGSizeZero
		}
		let measuredText = textForMeasure()
		if nowrap {
			return measureText(measuredText, inWidth: CGFloat.max)
		}
		if maxLines > 0 {
			let singleLine = measuredText.stringByReplacingOccurrencesOfString("\r", withString: "").stringByReplacingOccurrencesOfString("\n", withString: "")
			let singleLineHeight = measureText(singleLine, inWidth: CGFloat.max).height + 1
			var size = measureText(measuredText, inWidth: bounds.width)
			let maxHeight = singleLineHeight * CGFloat(maxLines)
			if size.height > maxHeight {
				size.height = maxHeight
			}
			return size
		}
		return measureText(measuredText, inWidth: bounds.width)
	}


	private func measureText(text: String, inWidth width: CGFloat) -> CGSize {
		let constraintSize = CGSize(width: width, height: CGFloat.max)
		var size = text.boundingRectWithSize(constraintSize,
			options: NSStringDrawingOptions.UsesLineFragmentOrigin,
			attributes: [NSFontAttributeName: resolveFont()],
			context: nil).size
		size.width += padding.left + padding.right
		size.height += padding.top + padding.bottom
		return size
	}


	private func resolveFont() -> UIFont {
		return font ?? UIFont.systemFontOfSize(UIFont.systemFontSize())
	}

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
				try applyFontValue(attribute, value: attribute.value, context: context)
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

		let text = element as! TextElement

		if let name = fontName, size = fontSize {
			text.font = font(name, size)
		}
		else if let name = fontName {
			text.font = font(name, UIFont.systemFontSize())
		}
		else if let size = fontSize {
			text.font = UIFont.systemFontOfSize(size)
		}
		text.padding = padding
		text.color = color
		text.maxLines = maxLines
		text.nowrap = nowrap
		text.textAlignment = textAlignment
	}


	// MARK: - Internals


	private func applyFontValue(attribute: DeclarationAttribute, value: DeclarationValue, context: DeclarationContext) throws {
		switch value {
			case .value(let string):
				var size: Float = 0
				if NSScanner(string: string).scanFloat(&size) {
					fontSize = CGFloat(size)
				}
				else {
					fontName = string
				}
			case .list(let values):
				for value in values {
					try applyFontValue(attribute, value: value, context: context)
				}
			default:
				throw DeclarationError("Font attributes expected", attribute, context)
		}
	}


	func font(name: String, _ size: CGFloat) -> UIFont {
		return UIFont(name: name, size: size) ?? UIFont.systemFontOfSize(size)
	}

	static var textAlignmentByName: [String: NSTextAlignment] = [
		"left": NSTextAlignment.Left,
		"right": NSTextAlignment.Right,
		"center": NSTextAlignment.Center,
		"justified": NSTextAlignment.Justified,
		"natural": NSTextAlignment.Natural
	]
}




