//
// Created by Michael Vlasov on 28.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit





open class ImageElement: ContentElement {
	var size = CGSize.zero

	open var imageAlignment = UIViewContentMode.center {
		didSet {
			initializeView()
		}
	}

	open var image: UIImage? {
		didSet {
			initializeView()
		}
	}


	public override init() {
		super.init()
	}

	// MARK: - UiContentElement


	open override func initializeView() {
		super.initializeView()
		if let imageView = view as? UIImageView {
			imageView.image = image
			imageView.contentMode = imageAlignment
		}
	}


	// MARK: - UiElement


	open override func createView() -> UIView {
		return UIImageView(image: nil)
	}


	open override func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		return SizeMeasure(width: size.width, height: size.height)
	}


	open override func layoutContent(inBounds bounds: CGRect) {
		frame = CGRect(origin: bounds.origin, size: size)
	}
}





class ImageElementDefinition: ContentElementDefinition {
	var source: UIImage?
	var size = CGSize.zero
	var fixedSize = false
	var imageAlignment = UIViewContentMode.center

	override func applyDeclarationAttribute(_ attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		if isElementValue {
			source = try context.getImage(attribute, value: .value(attribute.name))
			return
		}
		switch attribute.name {
			case "size":
				size = try context.getSize(attribute)
			case "fixed-size":
				fixedSize = try context.getBool(attribute)
			case "image-alignment":
				imageAlignment = try context.getEnum(attribute, ImageElementDefinition.imageAlignments)
			default:
				try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
		}
	}


	override func createElement() -> FragmentElement {
		return ImageElement()
	}


	override func initialize(_ element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)

		let image = element as! ImageElement
		image.image = source
		image.size = size
		image.imageAlignment = imageAlignment
	}


	private static let imageAlignments: [String:UIViewContentMode] = [
		"scale-to-fill": .scaleToFill,
		"scale-aspect-fit": .scaleAspectFit,
		"scale-aspect-fill": .scaleAspectFill,
		"redraw": .redraw,
		"center": .center,
		"top": .top,
		"bottom": .bottom,
		"left": .left,
		"right": .right,
		"top-left": .topLeft,
		"top-right": .topRight,
		"bottom-left": .bottomLeft,
		"bottom-right": .bottomRight
	]
}
