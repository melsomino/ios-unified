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

	var nowrap = false

	public var font: UIFont? {
		didSet {
			effectivePaddingDirty = true
			initializeView()
		}
	}

	public var baselineFontBottom: UIFont? {
		didSet {
			effectivePaddingDirty = true
			initializeView()
		}
	}

	public var baselineFontTop: UIFont? {
		didSet {
			effectivePaddingDirty = true
			initializeView()
		}
	}

	public var padding = UIEdgeInsetsZero {
		didSet {
			effectivePaddingDirty = true
			initializeView()
		}
	}

	public var effectivePadding: UIEdgeInsets {
		if effectivePaddingDirty {
			let effectiveFont = font ?? TextElement.defaultFont
			effectivePaddingValue = padding
			if let refFont = baselineFontTop {
				let ownAscender = abs(effectiveFont.ascender)
				let refAscender = abs(refFont.ascender)
				if refAscender > ownAscender {
					effectivePaddingValue.top += refAscender - ownAscender
				}
			}
			if let refFont = baselineFontBottom {
				let ownDescender = abs(effectiveFont.descender)
				let refDescender = abs(refFont.descender)
				if refDescender > ownDescender {
					effectivePaddingValue.bottom += refDescender - ownDescender
				}
			}
			effectivePaddingDirty = false
		}
		return effectivePaddingValue
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
			if let label = view as? TextElementLabel {
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

	// MARK: - ContentElement


	public override func initializeView() {
		super.initializeView()
		guard let view = view as? TextElementLabel else {
			return
		}
		view.textAlignment = textAlignment ?? .Natural
		view.backgroundColor = backgroundColor ?? UIColor.clearColor()
		view.font = font ?? TextElement.defaultFont
		view.padding = effectivePadding
		view.textColor = color ?? UIColor.darkTextColor()
		view.numberOfLines = maxLines ?? 0
		view.lineBreakMode = .ByTruncatingTail
		view.text = text
	}


	// MARK: - FragmentElement


	public override func createView() -> UIView {
		return TextElementLabel()
	}



	public override func bind(toModel values: [Any?]) {
		super.bind(toModel: values)
		if let textBinding = textDefinition.text {
			text = textBinding.evaluate(values)
		}
		if let boundHidden = definition.boundHidden(values) {
			hidden = boundHidden
		}
	}


	public override var visible: Bool {
		return !hidden
	}


	public override func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		let measured_text = textForMeasure()
		if measured_text.isEmpty {
			return SizeMeasure.zero
		}
		let font = self.font ?? TextElement.defaultFont
		var text_size = measureText(measured_text, font: font, inWidth: nowrap ? CGFloat.max : bounds.width)
		if maxLines > 0 {
			let line_height = font.lineHeight
			let max_height = line_height * CGFloat(maxLines)
			if text_size.height > max_height {
				text_size.height = max_height
			}
		}
		var size = SizeMeasure(width: (nowrap ? text_size.width : 0, text_size.width), height: text_size.height)

		let padding = effectivePadding
		size.width.min += padding.left + padding.right
		size.width.max += padding.left + padding.right
		if size.width.min > bounds.width {
			size.width.min = bounds.width
		}
		if size.width.max > bounds.width {
			size.width.max = bounds.width
		}
		size.height += padding.top + padding.bottom
		return size
	}



	// MARK: - Internals

	private var effectivePaddingDirty = true
	private var effectivePaddingValue = UIEdgeInsetsZero

	private func textForMeasure() -> String {
		return text ?? ""
	}



	private func measureText(text: String, font: UIFont, inWidth width: CGFloat) -> CGSize {
		return TextElement.measureText(text, font: font, padding: padding, inWidth: width)
	}



	public static func measureText(text: String?, font: UIFont?, padding: UIEdgeInsets, inWidth width: CGFloat) -> CGSize {
		guard let text = text where !text.isEmpty else {
			return CGSizeZero
		}
		let font = font ?? UIFont.systemFontOfSize(UIFont.systemFontSize())
		let constraintSize = CGSize(width: width, height: CGFloat.max)
		var size = text.boundingRectWithSize(constraintSize,
			options: NSStringDrawingOptions.UsesLineFragmentOrigin,
			attributes: [NSFontAttributeName: font],
			context: nil).size
		size.width += padding.left + padding.right
		size.height += padding.top + padding.bottom
		return size
	}


	static var defaultFont: UIFont {
		return UIFont.systemFontOfSize(UIFont.labelFontSize())
	}
}





public class TextElementDefinition: ContentElementDefinition {
	var padding: UIEdgeInsets = UIEdgeInsetsZero
	var font: UIFont?
	var baselineFontBottom: UIFont?
	var baselineFontTop: UIFont?
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
			case "baseline-font-bottom":
				baselineFontBottom = try context.getFont(attribute, defaultFont: baselineFontBottom ?? font)
			case "baseline-font-top":
				baselineFontTop = try context.getFont(attribute, defaultFont: baselineFontTop ?? font)
			case "baseline-font":
				baselineFontBottom = try context.getFont(attribute, defaultFont: font)
				baselineFontTop = baselineFontBottom
			case "font":
				font = try context.getFont(attribute, defaultFont: font)
			case "max-lines":
				maxLines = Int(try context.getFloat(attribute))
			case "nowrap":
				nowrap = try context.getBool(attribute)
			case "color":
				color = try context.getColor(attribute)
			case "text-alignment":
				textAlignment = try context.getEnum(attribute, TextElementDefinition.textAlignmentByName)
			case "nowrap":
				nowrap = try context.getBool(attribute)
			default:
				if try context.applyInsets(&padding, name: "padding", attribute: attribute) {
				}
				else {
					try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
				}
		}
	}



	public override func createElement() -> FragmentElement {
		return TextElement()
	}



	public override func initialize(element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)
		guard let text = element as? TextElement else {
			return
		}

		text.padding = padding
		text.font = font
		text.baselineFontBottom = baselineFontBottom
		text.baselineFontTop = baselineFontTop
		text.color = color
		text.maxLines = maxLines
		text.nowrap = nowrap
		text.textAlignment = textAlignment
	}


	// MARK: - Internals


	static var textAlignmentByName: [String:NSTextAlignment] = [
		"left": NSTextAlignment.Left,
		"right": NSTextAlignment.Right,
		"center": NSTextAlignment.Center,
		"justified": NSTextAlignment.Justified,
		"natural": NSTextAlignment.Natural
	]
}





public class TextElementLabel: UILabel {
	public var padding = UIEdgeInsetsZero


	// MARK: - UILabel


	public override func drawTextInRect(rect: CGRect) {
		super.drawTextInRect(UIEdgeInsetsInsetRect(rect, padding))
	}


	// MARK: - Internals

}



