//
// Created by Michael Vlasov on 28.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class UiImage: UiContentElement {
	var size = CGSizeZero
	public var fixedSizeValue = false
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


	public override var fixedSize: Bool {
		return fixedSizeValue
	}

	public override func measureMaxSize(bounds: CGSize) -> CGSize {
		return visible ? size : CGSizeZero
	}


	public override func measureSize(bounds: CGSize) -> CGSize {
		return visible ? size : CGSizeZero
	}


	public override func layout(bounds: CGRect) -> CGRect {
		if fixedSize {
			self.frame = CGRectMake(bounds.origin.x, bounds.origin.y, size.width, size.height)
		}
		else {
			self.frame = bounds
		}
		return frame
	}
}


class UiImageFactory: UiContentElementFactory {
	var source: UIImage?
	var size = CGSizeZero
	var fixedSize = false
	var imageAlignment = UIViewContentMode.Center

	override func create() -> UiElement {
		return UiImage()
	}

	override func applyDeclarationAttribute(attribute: DeclarationAttribute, context: DeclarationContext) throws {
		switch attribute.name {
			case "size":
				size = try context.getSize(attribute)
			case "fixed-size":
				fixedSize = try context.getBool(attribute)
			case "source":
				source = try context.getImage(attribute)
			case "image-alignment":
				imageAlignment = try context.getEnum(attribute, UiImageFactory.imageAlignments)
			default:
				try super.applyDeclarationAttribute(attribute, context: context)
		}
	}

	override func initialize(item: UiElement, content: [UiElement]) {
		super.initialize(item, content: content)

		let image = item as! UiImage
		image.image = source
		image.size = size
		image.fixedSizeValue = fixedSize
		image.imageAlignment = imageAlignment
	}


	private static let imageAlignments: [String: UIViewContentMode] = [
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
