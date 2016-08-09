//
// Created by Michael Vlasov on 18.07.16.
//

import Foundation

import Foundation
import UIKit

public class HtmlElement: ContentElement {

	public var htmlDefinition: HtmlElementDefinition {
		return definition as! HtmlElementDefinition
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

	public var color: UIColor? {
		didSet {
			initializeView()
		}
	}

	public var autoHideEmptyText = true

	private func getLastParagraphRange(string: NSMutableAttributedString) -> NSRange {
		if string.length == 0 {
			return NSMakeRange(0, 0)
		}
		let s = string.string as NSString
		return s.paragraphRangeForRange(NSMakeRange(string.length - 1, 1))
	}

	private func removeEmptyLinesFromEnd(string: NSAttributedString) -> NSAttributedString {
		if !string.string.hasSuffix("\n") {
			return string
		}
		return removeEmptyLinesFromEnd(string.attributedSubstringFromRange(NSMakeRange(0, string.length - 1)))
	}


	public var html: String? {
		didSet {
			guard var html = html else {
				attributedText = nil
				return
			}
			guard !html.isEmpty else {
				attributedText = nil
				return
			}
			let font = resolveFont()
			html = "<div style='font-family: \"\(font.familyName)\"; font-size: \(font.pointSize)'>\(html)</div>"
			let options: [String:AnyObject] = [
				NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
				NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding,
			]
			let attributed = try! NSAttributedString(data: html.dataUsingEncoding(NSUTF8StringEncoding)!, options: options, documentAttributes: nil)
//			let builder = removeEmptyLinesFromEnd(attributed).mutableCopy() as! NSMutableAttributedString
//			let lastParagraphRange = getLastParagraphRange(builder)
//			let lastParagraphStyle = builder.attribute(NSParagraphStyleAttributeName, atIndex: lastParagraphRange.location, effectiveRange: nil)
//			let newLastParagraphStyle = (lastParagraphStyle ?? NSParagraphStyle.defaultParagraphStyle()).mutableCopy() as! NSMutableParagraphStyle
//			newLastParagraphStyle.paragraphSpacing = 0
//			builder.setAttributes([NSParagraphStyleAttributeName: newLastParagraphStyle], range: lastParagraphRange)
//			attributedText = (builder.copy() as! NSAttributedString)
			attributedText = attributed
		}
	}


	public var attributedText: NSAttributedString? {
		didSet {
			if let label = view as? UILabel {
				label.attributedText = attributedText
			}
			if autoHideEmptyText {
				hidden = attributedText == nil || attributedText!.length == 0
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
		guard let label = view as? UILabel else {
			return
		}
		label.font = font ?? defaultFont
		label.textColor = color ?? defaultColor
		label.numberOfLines = maxLines ?? defaultMaxLines
		label.lineBreakMode = nowrap ? .ByClipping : .ByTruncatingTail
		label.text = html
	}


	public override func createView() -> UIView {
		return UILabel()
	}


	// MARK: - UiElement


	public override func bind(toModel values: [Any?]) {
		super.bind(toModel: values)
		if let htmlBinding = htmlDefinition.html {
			html = htmlBinding.evaluate(values)
		}
	}


	public override var visible: Bool {
		return !hidden && html != nil && !html!.isEmpty
	}


	public override func measureContent(inBounds bounds: CGSize) -> CGSize {
		return visible ? measureTextSize(inBounds: bounds) : CGSizeZero
	}



	// MARK: - Internals


	private var defaultMaxLines = 0
	private var defaultFont: UIFont?
	private var defaultColor: UIColor?

	private func attributedTextForMeasure() -> NSAttributedString {
		return attributedText ?? NSAttributedString(string: "")
	}


	private func measureTextSize(inBounds bounds: CGSize) -> CGSize {
		guard visible else {
			return CGSizeZero
		}
		let measuredText = attributedTextForMeasure()
		if nowrap {
			return measureText(measuredText, inWidth: CGFloat.max)
		}
		if maxLines > 0 {
			let singleLine = measuredText.string.stringByReplacingOccurrencesOfString("\r", withString: "").stringByReplacingOccurrencesOfString("\n", withString: "")
			let singleLineHeight = measureText(NSAttributedString(string: singleLine), inWidth: CGFloat.max).height + 1
			var size = measureText(measuredText, inWidth: bounds.width)
			let maxHeight = singleLineHeight * CGFloat(maxLines)
			if size.height > maxHeight {
				size.height = maxHeight
			}
			return size
		}
		return measureText(measuredText, inWidth: bounds.width)
	}



	private func measureText(text: NSAttributedString, inWidth width: CGFloat) -> CGSize {
		let constraintSize = CGSize(width: width, height: CGFloat.max)
		let size = text.boundingRectWithSize(constraintSize,
			options: NSStringDrawingOptions.UsesLineFragmentOrigin,
			context: nil).size
		return size
	}


	private func resolveFont() -> UIFont {
		return font ?? UIFont.systemFontOfSize(UIFont.systemFontSize())
	}
}



public class HtmlElementDefinition: ContentElementDefinition {
	var fontName: String?
	var fontSize: CGFloat?
	var maxLines = 0
	var nowrap = false
	var color: UIColor?
	var html: DynamicBindings.Expression?


	// MARK: - UiElementDefinition


	public override func applyDeclarationAttribute(attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		if isElementValue {
			html = try context.getExpression(attribute, .value(attribute.name))
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
			default:
				try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
		}
	}


	public override func createElement() -> FragmentElement {
		return HtmlElement()
	}


	public override func initialize(element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)

		let html = element as! HtmlElement
		if let name = fontName, size = fontSize {
			html.font = font(name, size)
		}
		else if let name = fontName {
			html.font = font(name, UIFont.systemFontSize())
		}
		else if let size = fontSize {
			html.font = UIFont.systemFontOfSize(size)
		}
		html.color = color
		html.maxLines = maxLines
		html.nowrap = nowrap
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
}
