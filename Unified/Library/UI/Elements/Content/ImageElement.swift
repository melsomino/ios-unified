//
// Created by Michael Vlasov on 28.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit





public class ImageElement: ContentElement {
	var size = CGSizeZero

	public var imageAlignment = UIViewContentMode.Center {
		didSet {
			initializeView()
		}
	}

	public var image: UIImage? {
		didSet {
			initializeView()
		}
	}


	public override init() {
		super.init()
	}

	// MARK: - UiContentElement


	public override func initializeView() {
		super.initializeView()
		if let imageView = view as? UIImageView {
			imageView.image = image
			imageView.contentMode = imageAlignment
		}
	}


	// MARK: - UiElement


	public override func createView() -> UIView {
		return UIImageView(image: nil)
	}


	public override func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		return SizeMeasure(width: size.width, height: size.height)
	}


	public override func layoutContent(inBounds bounds: CGRect) {
		frame = CGRect(origin: bounds.origin, size: size)
	}
}





class ImageElementDefinition: ContentElementDefinition {
	var source: UIImage?
	var size = CGSizeZero
	var fixedSize = false
	var imageAlignment = UIViewContentMode.Center

	override func applyDeclarationAttribute(attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
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


	override func initialize(element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)

		let image = element as! ImageElement
		image.image = source
		image.size = size
		image.imageAlignment = imageAlignment
	}


	private static let imageAlignments: [String:UIViewContentMode] = [
		"scale-to-fill": .ScaleToFill,
		"scale-aspect-fit": .ScaleAspectFit,
		"scale-aspect-fill": .ScaleAspectFill,
		"redraw": .Redraw,
		"center": .Center,
		"top": .Top,
		"bottom": .Bottom,
		"left": .Left,
		"right": .Right,
		"top-left": .TopLeft,
		"top-right": .TopRight,
		"bottom-left": .BottomLeft,
		"bottom-right": .BottomRight
	]
}
