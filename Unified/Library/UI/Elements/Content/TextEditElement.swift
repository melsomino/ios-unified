//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit





open class TextEditElement: ViewElement, TextEditDelegate {

	open var font: UIFont? {
		didSet {
			if let view = view as? TextEditView {
				view.font = font
			}
		}
	}

	open var textAlignment = NSTextAlignment.natural {
		didSet {
			if let view = view as? TextEditView {
				view.textAlignment = textAlignment
			}
		}
	}

	open var maxLines = 0 {
		didSet {
			if let view = view as? TextEditView {
				view.maxLines = maxLines
			}
		}
	}

	open var returnKey = UIReturnKeyType.default {
		didSet {
			if let view = view as? TextEditView {
				view.returnKeyType = returnKey
			}
		}
	}

	open var placeholder: String? {
		didSet {
			if let view = view as? TextEditView {
				view.placeholder = placeholder
			}
		}
	}

	open var placeholderColor: UIColor? {
		didSet {
			if let view = view as? TextEditView {
				view.placeholderColor = placeholderColor
			}
		}
	}

	open var padding = UIEdgeInsets.zero {
		didSet {
			if let view = view as? TextEditView {
				view.textContainerInset = padding
			}
		}
	}

	open var text: String? {
		didSet {
			if lockReflectView == 0 {
				(view as? TextEditView)?.text = text
			}
		}
	}
	private var lockReflectView = 0


	public init() {
		super.init(nil)
	}


	// MARK: - FragmentElement

	private func sizeOf(padding: UIEdgeInsets) -> CGSize {
		return CGSize(width: padding.left + padding.right, height: padding.top + padding.bottom)
	}



	open override func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		let font = self.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
		let maxLines = self.maxLines
		let padding = sizeOf(padding: self.padding)
		var size = TextElement.measureText(text, font: font, padding: UIEdgeInsets.zero, inWidth: bounds.width - padding.width)
		if size.height < font.lineHeight {
			size.height = font.lineHeight
		}
		if maxLines > 0 {
			let max_height = font.lineHeight * CGFloat(maxLines)
			if size.height > max_height {
				size.height = max_height
			}
		}
		return SizeMeasure(width: (1 + padding.width, bounds.width), height: size.height + padding.height)
	}



	open override func layoutContent(inBounds bounds: CGRect) {
		super.layoutContent(inBounds: bounds)
	}



	open override func createView() -> UIView {
		return TextEditView(frame: CGRect.zero, textContainer: nil)
	}



	open override func initializeView() {
		super.initializeView()
		guard let view = view as? TextEditView else {
			return
		}
		view.delegate = view
		view.textEditDelegate = self
		view.font = font
		view.textAlignment = textAlignment
		view.text = text
		view.maxLines = maxLines
		view.placeholder = placeholder
		view.placeholderColor = placeholderColor
		view.textContainerInset = UIEdgeInsets.zero
		view.textContainerInset = padding
		view.textContainer.lineFragmentPadding = 0
		view.returnKeyType = returnKey
	}



	open override func bind(toModel values: [Any?]) {
		super.bind(toModel: values)
		if let textBinding = (definition as? TextEditDefinition)?.text {
			text = textBinding.evaluate(values)
		}
	}



	// MARK: - TextEditDelegate


	open func textEditDidChange(_ textEdit: TextEditView) {
		guard let definition = definition as? TextEditDefinition else {
			return
		}
		lockReflectView += 1
		text = textEdit.text
		lockReflectView -= 1
		delegate?.tryExecuteAction(definition.textChangeAction, defaultArgs: text)
		if maxLines > 0 {
			delegate?.layoutChanged(forElement: self)
		}
	}



	open func textEditDidTapReturnKey(_ textEdit: TextEditView) {
		guard let definition = definition as? TextEditDefinition else {
			return
		}
		delegate?.tryExecuteAction(definition.returnKeyAction, defaultArgs: text)
	}



}





open class TextEditDefinition: ViewElementDefinition {

	open var font: UIFont?
	open var textAlignment = NSTextAlignment.natural
	open var maxLines = 0
	open var placeholder: String?
	open var placeholderColor: UIColor?
	open var textChangeAction: DynamicBindings.Expression?
	open var returnKeyAction: DynamicBindings.Expression?
	open var padding = UIEdgeInsets.zero
	open var returnKey = UIReturnKeyType.default
	open var text: DynamicBindings.Expression?

	open override func createElement() -> FragmentElement {
		return TextEditElement()
	}



	open override func initialize(_ element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)
		guard let element = element as? TextEditElement else {
			return
		}
		element.textAlignment = textAlignment
		element.font = font
		element.placeholder = placeholder
		element.placeholderColor = placeholderColor
		element.maxLines = maxLines
		element.padding = padding
		element.returnKey = returnKey
	}



	open override func applyDeclarationAttribute(_ attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		if isElementValue {
			text = try context.getExpression(attribute, .value(attribute.name))
			return
		}
		switch attribute.name {
			case "text-alignment":
				textAlignment = try context.getEnum(attribute, TextElementDefinition.textAlignmentByName)
			case "text-change-action":
				textChangeAction = try context.getExpression(attribute)
			case "return-key-action":
				returnKeyAction = try context.getExpression(attribute)
			case "max-lines":
				maxLines = Int(try context.getFloat(attribute))
			case "placeholder":
				placeholder = try context.getString(attribute)
			case "placeholder-color":
				placeholderColor = try context.getColor(attribute)
			case "font":
				font = try context.getFont(attribute, defaultFont: font)
			case "return-key":
				returnKey = try context.getEnum(attribute, TextEditDefinition.returnKeyByName)
			default:
				if try context.applyInsets(&padding, name: "padding", attribute: attribute) {
				}
				else {
					try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
				}
		}
	}

	private static let returnKeyByName: [String:UIReturnKeyType] = [
		"go": .go,
		"google": .google,
		"join": .join,
		"next": .next,
		"route": .route,
		"search": .search,
		"send": .send,
		"yahoo": .yahoo,
		"done": .done,
		"emergency-call": .emergencyCall
	]
}



public protocol TextEditDelegate: class {
	func textEditDidChange(_ textEdit: TextEditView)



	func textEditDidTapReturnKey(_ textEdit: TextEditView)
}

open class TextEditView: UITextView, UITextViewDelegate {

	open weak var textEditDelegate: TextEditDelegate?

	open var placeholderColor: UIColor? {
		didSet {
			setNeedsDisplay()
		}
	}

	open var maxLines: Int? {
		didSet {
//			textContainer.maximumNumberOfLines = maxLines ?? 0
			textContainer.lineBreakMode = .byTruncatingTail
			layoutManager.textContainerChangedGeometry(textContainer)
		}
	}

	open var placeholder: String? {
		didSet {
			setNeedsDisplay()
		}
	}

	open override var text: String! {
		didSet {
			setNeedsDisplay()
		}
	}


	open override func layoutSubviews() {
		super.layoutSubviews()
		if placeholder != nil {
			setNeedsDisplay()
		}
	}

	open override var attributedText: NSAttributedString! {
		didSet {
			setNeedsDisplay()
		}
	}


	open override func insertText(_ text: String) {
		super.insertText(text)
		setNeedsDisplay()
	}



	open override func draw(_ rect: CGRect) {
		super.draw(rect)
		if !editing && text.isEmpty && placeholder != nil && !placeholder!.isEmpty {
			let placeholderRect = UIEdgeInsetsInsetRect(bounds, textContainerInset)
			let paraStyle = NSMutableParagraphStyle()

			paraStyle.alignment = textAlignment
			paraStyle.paragraphSpacing = 0
			paraStyle.paragraphSpacingBefore = 0
			placeholder!.draw(in: placeholderRect, withAttributes: [
				NSForegroundColorAttributeName: placeholderColor ?? UIColor.lightGray,
				NSFontAttributeName: font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize),
				NSParagraphStyleAttributeName: paraStyle
			])
		}
	}


	// MARK: - UITextViewDelegate


	open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		guard (maxLines ?? 0) == 1 else {
			return true
		}
		if text == "\t" {
			return false
		}
		if text == "\n" {
			textEditDelegate?.textEditDidTapReturnKey(self)
			return false
		}
		return text.rangeOfCharacter(from: TextEditView.newLineOrTab) == nil
	}

	static let newLineOrTab = CharacterSet.union(CharacterSet.newlines, CharacterSet(charactersIn: "\t"))

	open func textViewDidBeginEditing(_ textView: UITextView) {
		editing = true
		setNeedsDisplay()
	}



	open func textViewDidEndEditing(_ textView: UITextView) {
		editing = false
		setNeedsDisplay()
	}



	open func textViewDidChange(_ textView: UITextView) {
		textEditDelegate?.textEditDidChange(self)
	}





	// MARK: - Internals

	private var editing = false

}
