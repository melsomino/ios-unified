//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class UiText: UiContentElement {

	public var textDefinition: UiTextDefinition {
		return definition as! UiTextDefinition
	}

	public var maxLines = 0 {
		didSet {
			initializeView()
		}
	}

	public var nowrap = false

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

	public var color: UIColor? {
		didSet {
			initializeView()
		}
	}

	public var autoHideEmptyText = true

	public var text: String? {
		didSet {
			if let label = view as? UiTextLabel {
				label.text = text
			}
			if autoHideEmptyText {
				hidden = text == nil || text!.isEmpty
			}
		}
	}


	public override required init() {
		super.init()
	}

	// MARK: - UiContentElement


	public override func onViewCreated() {
		super.onViewCreated()
		guard let label = view as? UILabel else {
			return
		}
		defaultMaxLines = label.numberOfLines
		defaultFont = label.font
		defaultColor = label.textColor
	}


	public override func initializeView() {
		super.initializeView()
		guard let label = view as? UiTextLabel else {
			return
		}
		label.font = font ?? defaultFont
		label.padding = padding
		label.textColor = color ?? defaultColor
		label.numberOfLines = maxLines ?? defaultMaxLines
		label.lineBreakMode = nowrap ? .ByClipping : .ByTruncatingTail
		label.text = text
	}


	// MARK: - UiElement


	public override func createView() -> UIView {
		return UiTextLabel()
	}


	public override func bind(toModel values: [Any?]) {
		super.bind(toModel: values)
		if let textBinding = textDefinition.text {
			text = textBinding.evaluate(values)
		}
	}


	public override var visible: Bool {
		return !hidden && text != nil && !text!.isEmpty
	}



	public override func measureSizeRange(inBounds bounds: CGSize) -> SizeRange {
		guard visible else {
			return SizeRange.zero
		}
		let size = measureTextSize(inBounds: bounds)
		if nowrap {
			return SizeRange(min: size, max: size)
		}
		return SizeRange(min: CGSizeZero, max: size)
	}



	public override func measureSize(inBounds bounds: CGSize) -> CGSize {
		return measureTextSize(inBounds: bounds)
	}


	// MARK: - Internals


	private var defaultMaxLines = 0
	private var defaultFont: UIFont?
	private var defaultColor: UIColor?

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
		return measureText(measuredText, bounds.width)
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



public class UiTextDefinition: UiContentElementDefinition {
	var fontName: String?
	var fontSize: CGFloat?
	var padding: UIEdgeInsets = UIEdgeInsetsZero
	var maxLines = 0
	var nowrap = false
	var color: UIColor?
	var text: UiBindings.Expression?


	// MARK: - UiElementDefinition


	public override func applyDeclarationAttribute(attribute: DeclarationAttribute, context: DeclarationContext) throws {
		switch attribute.name {
			case "font":
				try applyFontValue(attribute, value: attribute.value, context: context)
			case "max-lines":
				maxLines = Int(try context.getFloat(attribute))
			case "nowrap":
				nowrap = try context.getBool(attribute)
			case "color":
				color = try context.getColor(attribute)
			case "text":
				text = try context.getExpression(attribute)
			case "padding":
				padding = try context.getInsets(attribute)
			case "padding-top":
				padding.top = try context.getFloat(attribute)
			case "padding-bottom":
				padding.bottom = try context.getFloat(attribute)
			case "padding-left":
				padding.left = try context.getFloat(attribute)
			case "padding-right":
				padding.right = try context.getFloat(attribute)
			default:
				try super.applyDeclarationAttribute(attribute, context: context)
		}
	}


	public override func createElement() -> UiElement {
		return UiText()
	}


	public override func initialize(element: UiElement, children: [UiElement]) {
		super.initialize(element, children: children)

		let text = element as! UiText
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
	}


	// MARK: - Internals


	private func applyFontValue(attribute: DeclarationAttribute, value: DeclarationValue, context: DeclarationContext) throws {
		switch value {
			case .Value(let string):
				var size: Float = 0
				if NSScanner(string: string).scanFloat(&size) {
					fontSize = CGFloat(size)
				}
				else {
					fontName = string
				}
			case .List(let values):
				for value in values {
					try applyFontValue(attribute, value: value, context: context)
				}
			default:
				throw DeclarationError(message: "Font attributes expected", scanner: nil)
		}
	}


	func font(name: String, _ size: CGFloat) -> UIFont {
		return UIFont(name: name, size: size) ?? UIFont.systemFontOfSize(size)
	}
}



public class UiTextLabel: UILabel {
	public var padding = UIEdgeInsetsZero
	public var gradientBack = false

	public override func drawTextInRect(rect: CGRect) {
		super.drawTextInRect(UIEdgeInsetsInsetRect(rect, padding))
	}

}

