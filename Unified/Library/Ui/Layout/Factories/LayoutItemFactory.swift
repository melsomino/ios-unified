//
// Created by Власов М.Ю. on 16.06.16.
// Copyright (c) 2016 melsomino. All rights reserved.
//

import Foundation
import UIKit


public class LayoutItemFactory {
	var id: String?
	var contentFactories = [LayoutItemFactory]()





	public func createWith(target: Any) -> LayoutItem {
		return createWithMirror(Mirror(reflecting: target))
	}





	public func createWithMirror(mirror: Mirror) -> LayoutItem {
		var content = [LayoutItem]()
		for factory in contentFactories {
			content.append(factory.createWithMirror(mirror))
		}
		let item = findByIdInMirror(mirror) ?? create()
		initialize(item, content: content)
		return item
	}





	func findByIdInMirror(mirror: Mirror) -> LayoutItem? {
		if let id = id {
			for member in mirror.children {
				if let name = member.label {
					if name == id {
						return member.value as? LayoutItem
					}
				}
			}
		}
		return nil
	}





	func create() -> LayoutItem {
		return LayoutItem()
	}





	func initialize(item: LayoutItem, content: [LayoutItem]) {
		item.id = id
	}





	public static func fromDeclaration(element: DeclarationElement, context: DeclarationContext) throws -> LayoutItemFactory {
		var factory: LayoutItemFactory

		switch element.name {
			case "vertical":
				factory = LayoutStackFactory(direction: .Vertical)
			case "horizontal":
				factory = LayoutStackFactory(direction: .Horizontal)
			case "view":
				factory = LayoutViewFactory()
			case "label":
				factory = LayoutLabelFactory()
			case "layered":
				factory = LayoutLayeredFactory()
			default:
				throw DeclarationError(message: "Unknown markup element \"\(element.name)\"", scanner: nil)
		}


		var decorators = Decorators(target: factory)

		for index in 1 ..< element.attributes.count {
			let attribute = element.attributes[index]
			switch attribute.name {
				case "margin":
					decorators.padding.insets = try context.getInsets(attribute)
				case "margin-top":
					decorators.padding.insets.top = try context.getFloat(attribute)
				case "margin-left":
					decorators.padding.insets.left = try context.getFloat(attribute)
				case "margin-bottom":
					decorators.padding.insets.bottom = try context.getFloat(attribute)
				case "margin-right":
					decorators.padding.insets.right = try context.getFloat(attribute)
				case "align":
					decorators.align.anchor = try context.getEnum(attribute, LayoutItemFactory.alignAnchors)
				default:
					try factory.applyDeclarationAttribute(attribute, context: context)
			}
		}

		for child in element.children {
			factory.contentFactories.append(try LayoutItemFactory.fromDeclaration(child, context: context))
		}

		return decorators.result
	}





	static let alignments = [
		"fill": LayoutAlignment.Fill,
		"leading": LayoutAlignment.Leading,
		"tailing": LayoutAlignment.Tailing,
		"center": LayoutAlignment.Center
	]





	static let alignAnchors = [
		"top-left": LayoutAlignAnchor.TopLeft,
		"top": LayoutAlignAnchor.Top,
		"top-right": LayoutAlignAnchor.TopRight,
		"right": LayoutAlignAnchor.Right,
		"bottom-right": LayoutAlignAnchor.BottomRight,
		"bottom": LayoutAlignAnchor.Bottom,
		"bottom-left": LayoutAlignAnchor.BottomLeft,
		"left": LayoutAlignAnchor.Left,
		"center": LayoutAlignAnchor.Center
	]





	func applyDeclarationAttribute(attribute: DeclarationAttribute, context: DeclarationContext) throws {
		if attribute.name.hasPrefix("@") {
			id = attribute.name.substringFromIndex(attribute.name.startIndex.advancedBy(1))
		}
	}





	private struct Decorators {
		let target: LayoutItemFactory
		var first: LayoutItemFactory?
		var last: LayoutItemFactory?

		var cached_padding: LayoutPaddingFactory?
		var cached_align: LayoutAlignFactory?

		init(target: LayoutItemFactory) {
			self.target = target
		}

		var result: LayoutItemFactory {
			return first ?? target
		}

		var padding: LayoutPaddingFactory {
			mutating get {
				if cached_padding == nil {
					cached_padding = LayoutPaddingFactory()
					append(cached_padding!)
				}
				return cached_padding!
			}
		}

		var align: LayoutAlignFactory {
			mutating get {
				if cached_align == nil {
					cached_align = LayoutAlignFactory()
					append(cached_align!)
				}
				return cached_align!
			}
		}

		mutating func append(decorator: LayoutItemFactory) {
			decorator.contentFactories.append(target)
			if last == nil {
				last = decorator
			}
			else {
				last!.contentFactories[0] = decorator
			}
			first = decorator
		}
	}
}





class LayoutPaddingFactory: LayoutItemFactory {
	var insets = UIEdgeInsetsZero

	override func create() -> LayoutItem {
		return LayoutPadding()
	}

	override func initialize(item: LayoutItem, content: [LayoutItem]) {
		super.initialize(item, content: content)
		let item = item as! LayoutPadding
		item.insets = insets
		item.content = content[0]
	}
}





class LayoutAlignFactory: LayoutItemFactory {
	var anchor = LayoutAlignAnchor.TopLeft

	override func create() -> LayoutItem {
		return LayoutAlign()
	}

	override func initialize(item: LayoutItem, content: [LayoutItem]) {
		super.initialize(item, content: content)
		let align = item as! LayoutAlign
		align.anchor = anchor
		align.content = content[0]
	}
}





class LayoutLayeredFactory: LayoutItemFactory {

	override func create() -> LayoutItem {
		return LayoutLayered()
	}

	override func initialize(item: LayoutItem, content: [LayoutItem]) {
		super.initialize(item, content: content)
		let layered = item as! LayoutLayered
		layered.content = content
	}

}
