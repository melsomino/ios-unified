//
// Created by Michael Vlasov on 18.07.16.
//

import Foundation

import Foundation
import UIKit

open class HtmlElement: ContentElement {

	open var htmlDefinition: HtmlElementDefinition {
		return definition as! HtmlElementDefinition
	}

	open var maxLines = 0 {
		didSet {
			initializeView()
		}
	}

	open var nowrap = false

	open var font = UIFont.systemFont(ofSize: UIFont.systemFontSize) {
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

	private func getLastParagraphRange(_ string: NSMutableAttributedString) -> NSRange {
		if string.length == 0 {
			return NSMakeRange(0, 0)
		}
		let s = string.string as NSString
		return s.paragraphRange(for: NSMakeRange(string.length - 1, 1))
	}

	private func removeEmptyLinesFromEnd(_ string: NSAttributedString) -> NSAttributedString {
		if !string.string.hasSuffix("\n") {
			return string
		}
		return removeEmptyLinesFromEnd(string.attributedSubstring(from: NSMakeRange(0, string.length - 1)))
	}


	open var html: String? {
		didSet {
			guard var html = html else {
				attributedText = nil
				return
			}
			guard !html.isEmpty else {
				attributedText = nil
				return
			}
			html = "<div style='font-family: \"\(font.familyName)\"; font-size: \(Int(font.pointSize))'>\(html)</div>"

			var attributed: NSAttributedString!

			if let utf8Data = html.data(using: String.Encoding.utf8) {
				let options: [String:Any] = [
					NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
					NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue
				]
				attributed = try? NSAttributedString(data: utf8Data, options: options, documentAttributes: nil)
			}
			if attributed == nil {
				attributed = NSAttributedString(string: "")
			}

//			let builder = removeEmptyLinesFromEnd(attributed).mutableCopy() as! NSMutableAttributedString
			let builder = attributed.mutableCopy() as! NSMutableAttributedString
			let lastParagraphRange = getLastParagraphRange(builder)
			if lastParagraphRange.location  >= 0 && lastParagraphRange.location < attributed.string.characters.count && lastParagraphRange.length > 0 {
				let lastParagraphStyle = builder.attribute(NSParagraphStyleAttributeName, at: lastParagraphRange.location, effectiveRange: nil)
				var newLastParagraphStyle: NSMutableParagraphStyle
				if let last = lastParagraphStyle as? NSParagraphStyle {
					newLastParagraphStyle = last.mutableCopy() as! NSMutableParagraphStyle
				}
				else {
					newLastParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
				}
				newLastParagraphStyle.paragraphSpacing = 0
				builder.addAttribute(NSParagraphStyleAttributeName, value: newLastParagraphStyle, range: lastParagraphRange)
				attributed = (builder.copy() as! NSAttributedString)
			}
			attributedText = attributed
		}
	}


	open var attributedText: NSAttributedString? {
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


	open override func onViewCreated() {
		super.onViewCreated()
		guard let label = view as? UILabel else {
			return
		}
		defaultMaxLines = label.numberOfLines
		defaultColor = label.textColor
	}


	open override func initializeView() {
		super.initializeView()
		guard let label = view as? UILabel else {
			return
		}
		label.font = font
		label.textColor = color ?? defaultColor
		label.numberOfLines = maxLines
		label.lineBreakMode = nowrap ? .byClipping : .byTruncatingTail
		label.attributedText = attributedText
	}


	open override func createView() -> UIView {
		return UILabel()
	}


	// MARK: - UiElement


	open override func bind(toModel values: [Any?]) {
		super.bind(toModel: values)
		if let htmlBinding = htmlDefinition.html {
			html = htmlBinding.evaluate(values)
		}
	}


	open override var visible: Bool {
		return !hidden && html != nil && !html!.isEmpty
	}


	open override func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		return SizeMeasure(size: measureTextSize(inBounds: bounds))
	}



	// MARK: - Internals


	private var defaultMaxLines = 0
	private var defaultColor: UIColor?

	private func attributedTextForMeasure() -> NSAttributedString {
		return attributedText ?? NSAttributedString(string: "")
	}


	private func measureTextSize(inBounds bounds: CGSize) -> CGSize {
		guard visible else {
			return CGSize.zero
		}
		let measuredText = attributedTextForMeasure()
		if nowrap {
			return measureText(measuredText, inWidth: CGFloat.greatestFiniteMagnitude)
		}
		if maxLines > 0 {
			let singleLine = measuredText.string.replacingOccurrences(of: "\r", with: "").replacingOccurrences(of: "\n", with: "")
			let singleLineHeight = measureText(NSAttributedString(string: singleLine), inWidth: CGFloat.greatestFiniteMagnitude).height + 1
			var size = measureText(measuredText, inWidth: bounds.width)
			let maxHeight = singleLineHeight * CGFloat(maxLines)
			if size.height > maxHeight {
				size.height = maxHeight
			}
			return size
		}
		return measureText(measuredText, inWidth: bounds.width)
	}



	private func measureText(_ text: NSAttributedString, inWidth width: CGFloat) -> CGSize {
		let constraintSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
		let size = text.boundingRect(with: constraintSize,
			options: NSStringDrawingOptions.usesLineFragmentOrigin,
			context: nil).size
		return size
	}
}



open class HtmlElementDefinition: ContentElementDefinition {
	var font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
	var maxLines = 0
	var nowrap = false
	var color: UIColor?
	var html: DynamicBindings.Expression?


	// MARK: - UiElementDefinition


	open override func applyDeclarationAttribute(_ attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		if isElementValue {
			html = try context.getExpression(attribute, .value(attribute.name))
			return
		}
		switch attribute.name {
			case "font":
				font = try context.getFont(attribute, defaultFont: font)
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


	open override func createElement() -> FragmentElement {
		return HtmlElement()
	}


	open override func initialize(_ element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)

		let html = element as! HtmlElement
		html.font = font
		html.color = color
		html.maxLines = maxLines
		html.nowrap = nowrap
	}


	// MARK: - Internals


}
