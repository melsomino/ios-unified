//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

public class TextElement: ContentElement {

	public var textDefinition: TextElementDefinition {
		return definition as! TextElementDefinition
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

	public var textAlignment: NSTextAlignment? {
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

		guard let label = view as? UiTextLabel else {
			return
		}
		label.textAlignment = textAlignment ?? .Natural
		label.textBackgroundColor = backgroundColor
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
		return !hidden
	}



	public override func measureContent(inBounds bounds: CGSize) -> CGSize {
		guard visible else {
			return CGSizeZero
		}
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



public class TextElementDefinition: ContentElementDefinition {
	var fontName: String?
	var fontSize: CGFloat?
	var padding: UIEdgeInsets = UIEdgeInsetsZero
	var maxLines = 0
	var nowrap = false
	var color: UIColor?
	var textAlignment: NSTextAlignment?
	var text: DynamicBindings.Expression?


	// MARK: - UiElementDefinition


	public override func applyDeclarationAttribute(attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		if isElementValue {
			text = try context.getExpression(attribute, .value(attribute.name))
			return
		}
		switch attribute.name {
			case "font":
				try applyFontValue(attribute, value: attribute.value, context: context)
			case "max-lines":
				maxLines = Int(try context.getFloat(attribute))
			case "nowrap":
				nowrap = try context.getBool(attribute)
			case "color":
				color = try context.getColor(attribute)
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
			case "text-alignment":
				textAlignment = try context.getEnum(attribute, TextElementDefinition.textAlignmentByName)
			default:
				try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
		}
	}


	public override func createElement() -> FragmentElement {
		return TextElement()
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



public class UiTextLabel: UILabel {
	public var padding = UIEdgeInsetsZero
	public var textBackgroundColor: UIColor? {
		didSet {
			background_properties_changed()
		}
	}
	public var transparentGradientLeft: CGFloat? {
		didSet {
			background_properties_changed()
		}
	}


	// MARK: - UILabel


	public override func drawTextInRect(rect: CGRect) {
		super.drawTextInRect(UIEdgeInsetsInsetRect(rect, padding))
	}


	// MARK: - UIView


	public override func layoutSubviews() {
		super.layoutSubviews()
		guard let gradient = gradient_layer, left = transparentGradientLeft else {
			return
		}
		gradient.locations = [0, bounds.width > 0 ? left / bounds.width : 0, 1]
	}


	// MARK: - Internals

	private var gradient_layer: CAGradientLayer?
	private var default_background_color_assigned = false
	private var default_background_color: UIColor?

	private func check_default_background_color_assigned() {
		if !default_background_color_assigned {
			default_background_color = backgroundColor
			default_background_color_assigned = true
		}
	}

	private func resolve_background_color() -> UIColor? {
		check_default_background_color_assigned()
		return textBackgroundColor ?? default_background_color
	}

	private func background_properties_changed() {
		check_default_background_color_assigned()

		if let left = transparentGradientLeft, back_color = textBackgroundColor {
			if gradient_layer == nil {
				layer.backgroundColor = default_background_color?.CGColor
				gradient_layer = CAGradientLayer()
				layer.addSublayer(gradient_layer!)
			}
			let gradient = gradient_layer!
			gradient.startPoint = CGPointMake(0, 0.5)
			gradient.endPoint = CGPointMake(1, 0.5)

			gradient.colors = [back_color.colorWithAlphaComponent(0).CGColor, back_color.CGColor, back_color.CGColor]
			gradient.locations = [0, bounds.width > 0 ? left / bounds.width : 0, 1]
		}
		else {
			if gradient_layer != nil {
				gradient_layer!.removeFromSuperlayer()
				gradient_layer = nil
			}
			layer.backgroundColor = resolve_background_color()?.CGColor
		}
	}
}



