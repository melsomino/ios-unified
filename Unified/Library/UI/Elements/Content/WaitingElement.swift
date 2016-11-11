//
// Created by Власов М.Ю. on 10.11.16.
//

import Foundation
import UIKit


open class WaitingElement: ContentElement {


	open var style = UIActivityIndicatorViewStyle.gray {
		didSet {
			size = WaitingElementDefinition.sizeByStyle[style]!
			initializeView()
		}
	}

	public override init() {
		super.init()
	}


	// MARK: - UiContentElement


	open override func initializeView() {
		super.initializeView()
		if let view = view as? UIActivityIndicatorView {
			view.activityIndicatorViewStyle = style
			view.startAnimating()
		}
	}


	// MARK: - UiElement


	open override func createView() -> UIView {
		return UIActivityIndicatorView(activityIndicatorStyle: style)
	}



	open override func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		return SizeMeasure(width: size.width, height: size.height)
	}



	open override func layoutContent(inBounds bounds: CGRect) {
		frame = CGRect(origin: bounds.origin, size: size)
	}


	// MARK: - Internals


	var size = WaitingElementDefinition.sizeByStyle[.gray]!


}





class WaitingElementDefinition: ContentElementDefinition {
	var style = UIActivityIndicatorViewStyle.gray
	var size = CGSize.zero

	override func applyDeclarationAttribute(_ attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		switch attribute.name {
			case "size":
				size = try context.getSize(attribute)
			default:
				if let style = WaitingElementDefinition.styleByName[attribute.name] {
					self.style = style
				}
				else {
					try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
				}
		}
	}



	override func createElement() -> FragmentElement {
		return WaitingElement()
	}



	override func initialize(_ element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)

		if let element = element as? WaitingElement {
			element.style = style
			element.size = size
		}
	}



	static let sizeByStyle: [UIActivityIndicatorViewStyle: CGSize] = [
		.gray: calcDefaultSize(style: .gray),
		.white: calcDefaultSize(style: .white),
		.whiteLarge: calcDefaultSize(style: .whiteLarge)
	]

	private static func calcDefaultSize(style: UIActivityIndicatorViewStyle) -> CGSize {
		return UIActivityIndicatorView(activityIndicatorStyle: style).frame.size
	}

	private static let styleByName: [String: UIActivityIndicatorViewStyle] = [
		"gray": .gray,
		"white": .white,
		"white-large": .whiteLarge
	]
}
