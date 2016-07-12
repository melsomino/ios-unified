//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class UiText: UiContentElement {

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

	public var binding: UiBindings.Expression?

	public var text: String? {
		didSet {
			if let label = view as? UILabel {
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
		guard let label = view as? UILabel else {
			return
		}
		label.font = font ?? defaultFont
		label.textColor = color ?? defaultColor
		label.numberOfLines = maxLines ?? defaultMaxLines
		label.lineBreakMode = nowrap ? .ByClipping : .ByTruncatingTail
		label.text = text
	}


	// MARK: - UiElement


	public override func createView() -> UIView {
		return UILabel()
	}


	public override func bindValues(values: [Any?]) {
		super.bindValues(values)
		if let binding = binding {
			text = binding.evaluate(values)
		}
	}


	public override var visible: Bool {
		return !hidden && text != nil && !text!.isEmpty
	}


	public override var fixedSize: Bool {
		return nowrap
	}


	public override func measureMaxSize(bounds: CGSize) -> CGSize {
		guard visible else {
			return CGSizeZero
		}
		let measuredText = textForMeasure()
		if nowrap {
			return measureText(measuredText, CGFloat.max)
		}
		if maxLines > 0 {
			let singleLine = measuredText.stringByReplacingOccurrencesOfString("\r", withString: "").stringByReplacingOccurrencesOfString("\n", withString: "")
			let singleLineHeight = measureText(singleLine, CGFloat.max).height + 1
			var maxSize = measureText(measuredText, bounds.width)
			let maxHeight = singleLineHeight * CGFloat(maxLines)
			if maxSize.height > maxHeight {
				maxSize.height = maxHeight
			}
			return maxSize
		}
		return measureText(measuredText, bounds.width)
	}





	public override func measureSize(bounds: CGSize) -> CGSize {
		guard visible else {
			return CGSizeZero
		}
		let measuredText = textForMeasure()
		if nowrap {
			return measureText(measuredText, CGFloat.max)
		}
		if maxLines > 0 {
			let singleLine = measuredText.stringByReplacingOccurrencesOfString("\r", withString: "").stringByReplacingOccurrencesOfString("\n", withString: "")
			let singleLineHeight = measureText(singleLine, CGFloat.max).height + 1
			var size = measureText(measuredText, bounds.width)
			let maxHeight = singleLineHeight * CGFloat(maxLines)
			if size.height > maxHeight {
				size.height = maxHeight
			}
			return size
		}
		return measureText(measuredText, bounds.width)
	}





	// MARK: - Internals

	private var defaultMaxLines = 0
	private var defaultFont: UIFont?
	private var defaultColor: UIColor?

	private func textForMeasure() -> String {
		return text ?? ""
	}




	private func measureText(text: String, _ width: CGFloat) -> CGSize {
		let constraintSize = CGSize(width: width, height: CGFloat.max)
		let size = text.boundingRectWithSize(constraintSize,
			options: NSStringDrawingOptions.UsesLineFragmentOrigin,
			attributes: [NSFontAttributeName: resolveFont()],
			context: nil).size
		return size
	}


	private func resolveFont() -> UIFont {
		return font ?? UIFont.systemFontOfSize(UIFont.systemFontSize())
	}
}



class UiTextFactory: UiContentElementFactory {
	var fontName: String?
	var fontSize: CGFloat?
	var maxLines = 0
	var nowrap = false
	var color: UIColor?
	var binding: UiBindings.Expression?
	var text: String?

	override func create() -> UiElement {
		return UiText()
	}

	override func applyDeclarationAttribute(attribute: DeclarationAttribute, context: DeclarationContext) throws {
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
				let value = try context.getString(attribute)
				binding = context.bindings.parse(value)
				text = binding == nil ? value : nil
			default:
				try super.applyDeclarationAttribute(attribute, context: context)
		}
	}

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

	override func initialize(item: UiElement, content: [UiElement]) {
		super.initialize(item, content: content)

		let text = item as! UiText
		if let name = fontName, size = fontSize {
			text.font = font(name, size)
		}
		else if let name = fontName {
			text.font = font(name, UIFont.systemFontSize())
		}
		else if let size = fontSize {
			text.font = UIFont.systemFontOfSize(size)
		}
		text.color = color
		text.maxLines = maxLines
		text.nowrap = nowrap
		text.binding = self.binding
		text.text = self.text
	}

	func font(name: String, _ size: CGFloat) -> UIFont {
		return UIFont(name: name, size: size) ?? UIFont.systemFontOfSize(size)
	}
}
