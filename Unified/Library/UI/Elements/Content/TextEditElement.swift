//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit





public class TextEditElement: ViewElement, TextEditDelegate {

	public var font: UIFont? {
		didSet {
			if let view = view as? TextEditView {
				view.font = font
			}
		}
	}

	public var textAlignment = NSTextAlignment.Natural {
		didSet {
			if let view = view as? TextEditView {
				view.textAlignment = textAlignment
			}
		}
	}

	public var maxLines: Int? {
		didSet {
			if let view = view as? TextEditView {
				view.maxLines = maxLines
			}
		}
	}

	public var placeholder: String? {
		didSet {
			if let view = view as? TextEditView {
				view.placeholder = placeholder
			}
		}
	}

	public var placeholderColor: UIColor? {
		didSet {
			if let view = view as? TextEditView {
				view.placeholderColor = placeholderColor
			}
		}
	}

	public var padding = UIEdgeInsetsZero {
		didSet {
			if let view = view as? TextEditView {
				view.textContainerInset = padding
			}
		}
	}

	public var text: String? {
		return (view as? TextEditView)?.text
	}

	public init() {
		super.init(nil)
	}


	// MARK: - FragmentElement


	public override func createView() -> UIView {
		let view = TextEditView(frame: CGRectZero, textContainer: nil)
		view.delegate = view
		return view
	}


	public override func initializeView() {
		super.initializeView()
		guard let view = view as? TextEditView else {
			return
		}
		view.textEditDelegate = self
		view.font = font
		view.textAlignment = textAlignment
		view.maxLines = maxLines
		view.placeholder = placeholder
		view.placeholderColor = placeholderColor
		view.textContainerInset = UIEdgeInsetsZero
		view.textContainerInset = padding
		view.textContainer.lineFragmentPadding = 0
	}


	// MARK: - TextEditDelegate


	public func textEditDidChange(textEdit: TextEditView) {
		guard let definition = definition as? TextEditDefinition else {
			return
		}
		delegate?.tryExecuteAction(definition.textChangeAction)
	}


}





public class TextEditDefinition: ViewElementDefinition {

	public var font: UIFont?
	public var textAlignment = NSTextAlignment.Natural
	public var maxLines: Int?
	public var placeholder: String?
	public var placeholderColor: UIColor?
	public var textChangeAction: DynamicBindings.Expression?
	public var padding = UIEdgeInsetsZero

	public override func createElement() -> FragmentElement {
		return TextEditElement()
	}


	public override func initialize(element: FragmentElement, children: [FragmentElement]) {
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
	}


	public override func applyDeclarationAttribute(attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		switch attribute.name {
			case "text-alignment":
				textAlignment = try context.getEnum(attribute, TextElementDefinition.textAlignmentByName)
			case "text-change-action":
				textChangeAction = try context.getExpression(attribute)
			case "max-lines":
				maxLines = Int(try context.getFloat(attribute))
			case "placeholder":
				placeholder = try context.getString(attribute)
			case "placeholder-color":
				placeholderColor = try context.getColor(attribute)
			case "font":
				font = try context.getFont(attribute, defaultFont: font)
			default:
				if try context.applyInsets(&padding, name: "padding", attribute: attribute) {
				}
				else {
					try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
				}
		}
	}

}



public protocol TextEditDelegate: class {
	func textEditDidChange(textEdit: TextEditView)
}

public class TextEditView: UITextView, UITextViewDelegate {

	public weak var textEditDelegate: TextEditDelegate?

	public var placeholderColor: UIColor? {
		didSet {
			setNeedsDisplay()
		}
	}

	public var maxLines: Int? {
		didSet {
			textContainer.maximumNumberOfLines = maxLines ?? 0
			textContainer.lineBreakMode = .ByTruncatingTail
			layoutManager.textContainerChangedGeometry(textContainer)
		}
	}

	public var placeholder: String? {
		didSet {
			setNeedsDisplay()
		}
	}

	public override var text: String! {
		didSet {
			setNeedsDisplay()
		}
	}


	public override var attributedText: NSAttributedString! {
		didSet {
			setNeedsDisplay()
		}
	}


	public override func insertText(text: String) {
		super.insertText(text)
		setNeedsDisplay()
	}


	public override func drawRect(rect: CGRect) {
		super.drawRect(rect)
		if !editing && text.isEmpty && placeholder != nil && !placeholder!.isEmpty {
			let placeholderRect = UIEdgeInsetsInsetRect(bounds, textContainerInset)
			let paraStyle = NSMutableParagraphStyle()
			paraStyle.alignment = .Center
			paraStyle.paragraphSpacing = 0
			paraStyle.paragraphSpacingBefore = 0
			placeholder!.drawInRect(placeholderRect, withAttributes: [
				NSForegroundColorAttributeName: placeholderColor ?? UIColor.lightGrayColor(),
				NSFontAttributeName: font ?? UIFont.systemFontOfSize(UIFont.systemFontSize()),
				NSParagraphStyleAttributeName: paraStyle
			])
		}
	}


	// MARK: - UITextViewDelegate


	public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
		guard (maxLines ?? 0) == 1 else {
			return true
		}
		if text == "\t" {
			return false
		}
		return text.rangeOfCharacterFromSet(TextEditView.newLineOrTab) == nil
	}

	static let newLineOrTab = NSCharacterSet.union(NSCharacterSet.newlineCharacterSet(), NSCharacterSet(charactersInString: "\t"))

	public func textViewDidBeginEditing(textView: UITextView) {
		editing = true
		setNeedsDisplay()
	}


	public func textViewDidEndEditing(textView: UITextView) {
		editing = false
		setNeedsDisplay()
	}


	public func textViewDidChange(textView: UITextView) {
		textEditDelegate?.textEditDidChange(self)
	}


	// MARK: - Internals

	private var editing = false

}