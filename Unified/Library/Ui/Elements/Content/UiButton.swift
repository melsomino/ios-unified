//
// Created by Michael Vlasov on 28.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class UiButton: UiContentElement {

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

	public var title: String? {
		didSet {
			initializeView()
		}
	}

	public var image: UIImage? {
		didSet {
			initializeView()
		}
	}


	public var onTouchUpInside: (() -> Void)?

	public override required init() {
		super.init()
	}

	// MARK: - UiContentElement


	public override func initializeView() {
		super.initializeView()
		if let button = view as? UIButton {
			button.titleLabel?.font = resolveFont()
			button.setTitleColor(color, forState: .Normal)
			button.setTitle(title, forState: .Normal)
			button.setImage(image, forState: .Normal)
		}
	}


	// MARK: - UiElement


	public override func createView() -> UIView {
		return UIButton(type: .System)
	}


	public override var fixedSize: Bool {
		return true
	}


	public override func measureMaxSize(bounds: CGSize) -> CGSize {
		guard visible else {
			return CGSizeZero
		}
		return measureText(textForMeasure(), CGFloat.max)
	}


	public override func measureSize(bounds: CGSize) -> CGSize {
		guard visible else {
			return CGSizeZero
		}
		return measureText(textForMeasure(), CGFloat.max)
	}





	// MARK: - Internals


	private func textForMeasure() -> String {
		return title ?? ""
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



class UiButtonDefinition: UiContentElementDefinition {
	var fontName: String?
	var fontSize: CGFloat?
	var color: UIColor?
	var title: String?
	var image: UIImage?

	override func applyDeclarationAttribute(attribute: DeclarationAttribute, context: DeclarationContext) throws {
		switch attribute.name {
			case "font":
				try applyFontValue(attribute, value: attribute.value, context: context)
			case "color":
				color = try context.getColor(attribute)
			case "title":
				title = try context.getString(attribute)
			case "image":
				image = try context.getImage(attribute)
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

	override func createElement() -> UiElement {
		return UiButton()
	}

	override func initialize(element: UiElement, children: [UiElement]) {
		super.initialize(element, children: children)

		let button = element as! UiButton
		if let name = fontName, size = fontSize {
			button.font = font(name, size)
		}
		else if let name = fontName {
			button.font = font(name, UIFont.systemFontSize())
		}
		else if let size = fontSize {
			button.font = UIFont.systemFontOfSize(size)
		}
		button.color = color
		button.image = image
	}

	func font(name: String, _ size: CGFloat) -> UIFont {
		return UIFont(name: name, size: size) ?? UIFont.systemFontOfSize(size)
	}
}
