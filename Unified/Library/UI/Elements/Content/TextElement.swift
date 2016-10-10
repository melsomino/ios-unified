//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore




open class TextElement: ContentElement {

	open var textDefinition: TextElementDefinition {
		return definition as! TextElementDefinition
	}

	open var maxLines = 0 {
		didSet {
			initializeView()
		}
	}

	var nowrap = false

	open var font: UIFont? {
		didSet {
			effectivePaddingDirty = true
			initializeView()
		}
	}

	open var baselineFontBottom: UIFont? {
		didSet {
			effectivePaddingDirty = true
			initializeView()
		}
	}

	open var baselineFontTop: UIFont? {
		didSet {
			effectivePaddingDirty = true
			initializeView()
		}
	}

	open var padding = UIEdgeInsets.zero {
		didSet {
			effectivePaddingDirty = true
			initializeView()
		}
	}

	open var effectivePadding: UIEdgeInsets {
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

	open var textAlignment: NSTextAlignment? {
		didSet {
			initializeView()
		}
	}
	open var color: UIColor? {
		didSet {
			initializeView()
		}
	}

	open var autoHideEmptyText = true

	open var text: String? {
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


	open override func initializeView() {
		super.initializeView()
		guard let view = view as? TextElementLabel else {
			return
		}
		view.textAlignment = textAlignment ?? .natural
		view.backgroundColor = backgroundColor ?? UIColor.clear
		view.font = font ?? TextElement.defaultFont
		view.padding = effectivePadding
		view.textColor = color ?? UIColor.darkText
		view.numberOfLines = maxLines ?? 0
		view.lineBreakMode = .byTruncatingTail
		view.text = text
	}


	// MARK: - FragmentElement


	open override func createView() -> UIView {
		return TextElementLabel()
	}



	open override func bind(toModel values: [Any?]) {
		super.bind(toModel: values)
		if let textBinding = textDefinition.text {
			text = textBinding.evaluate(values)
		}
		if let boundHidden = definition.boundHidden(values) {
			hidden = boundHidden
		}
	}


	open override var visible: Bool {
		return !hidden
	}


	open override func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		let measured_text = textForMeasure()
		if measured_text.isEmpty {
			return SizeMeasure.zero
		}
		let font = self.font ?? TextElement.defaultFont
		var text_size = measureText(measured_text, font: font, inWidth: nowrap ? CGFloat.greatestFiniteMagnitude : bounds.width)
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
	private var effectivePaddingValue = UIEdgeInsets.zero

	private func textForMeasure() -> String {
		return text ?? ""
	}



	private func measureText(_ text: String, font: UIFont, inWidth width: CGFloat) -> CGSize {
		return TextElement.measureText(text, font: font, padding: padding, inWidth: width)
	}



	open static func measureText(_ text: String?, font: UIFont?, padding: UIEdgeInsets, inWidth width: CGFloat) -> CGSize {
		guard let text = text , !text.isEmpty else {
			return CGSize.zero
		}
		let font = font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
		let constraintSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
		var size = text.boundingRect(with: constraintSize,
			options: NSStringDrawingOptions.usesLineFragmentOrigin,
			attributes: [NSFontAttributeName: font],
			context: nil).size
		size.width += padding.left + padding.right
		size.height += padding.top + padding.bottom
		return size
	}


	static var defaultFont: UIFont {
		return UIFont.systemFont(ofSize: UIFont.labelFontSize)
	}
}





open class TextElementDefinition: ContentElementDefinition {
	var padding: UIEdgeInsets = UIEdgeInsets.zero
	var font: UIFont?
	var baselineFontBottom: UIFont?
	var baselineFontTop: UIFont?
	var maxLines = 0
	var nowrap = false
	var color: UIColor?
	var textAlignment: NSTextAlignment?
	var text: DynamicBindings.Expression?


	// MARK: - UiElementDefinition


	open override func applyDeclarationAttribute(_ attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
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



	open override func createElement() -> FragmentElement {
		return TextElement()
	}



	open override func initialize(_ element: FragmentElement, children: [FragmentElement]) {
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
		"left": NSTextAlignment.left,
		"right": NSTextAlignment.right,
		"center": NSTextAlignment.center,
		"justified": NSTextAlignment.justified,
		"natural": NSTextAlignment.natural
	]
}





open class TextElementLabel: UILabel {
	open var padding = UIEdgeInsets.zero


	// MARK: - UILabel


	open override func drawText(in rect: CGRect) {
		super.drawText(in: UIEdgeInsetsInsetRect(rect, padding))
	}


	// MARK: - Internals

}



