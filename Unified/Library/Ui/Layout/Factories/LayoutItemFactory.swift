//
// Created by Власов М.Ю. on 16.06.16.
// Copyright (c) 2016 melsomino. All rights reserved.
//

import Foundation
import UIKit

struct LayoutMarkupError: ErrorType {
	let message: String
	init(_ message: String) {
		self.message = message
	}
}


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
		apply(item, content)
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


	func apply(item: LayoutItem, _ content: [LayoutItem]) {
	}


	public static func parse(source: [String]) throws -> LayoutItemFactory {
		let token = try MarkupToken.parse(source)
		return try fromMarkup(token)
	}


	public static func fromMarkup(markup: MarkupToken) throws -> LayoutItemFactory {
		var factory: LayoutItemFactory

		switch markup.name {
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
				throw LayoutMarkupError("Unknown markup element \"\(markup.name)\"")
		}


		var decorators = Decorators(target: factory)

		for (name, value) in markup.attributes {
			switch name {
				case "margin":
					decorators.padding.insets = try value.getInsets()
				case "margintop":
					decorators.padding.insets.top = try value.getFloat()
				case "marginleft":
					decorators.padding.insets.left = try value.getFloat()
				case "marginbottom":
					decorators.padding.insets.bottom = try value.getFloat()
				case "marginright":
					decorators.padding.insets.right = try value.getFloat()
				case "align":
					decorators.align.anchor = try value.getEnum(LayoutItemFactory.alignAnchors)
				default:
					try factory.applyMarkupAttributeWithName(name, value: value)
			}
		}

		for child in markup.children {
			factory.contentFactories.append(try LayoutItemFactory.fromMarkup(child))
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
		"topleft": LayoutAlignAnchor.TopLeft,
		"top": LayoutAlignAnchor.Top,
		"topright": LayoutAlignAnchor.TopRight,
		"right": LayoutAlignAnchor.Right,
		"bottomright": LayoutAlignAnchor.BottomRight,
		"bottom": LayoutAlignAnchor.Bottom,
		"bottomleft": LayoutAlignAnchor.BottomLeft,
		"left": LayoutAlignAnchor.Left,
		"center": LayoutAlignAnchor.Center
	]



	func applyMarkupAttributeWithName(name: String, value: MarkupValue) throws {
		if name == "id" {
			id = try value.getString()
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

	override func apply(item: LayoutItem, _ content: [LayoutItem]) {
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

	override func apply(item: LayoutItem, _ content: [LayoutItem]) {
		let align = item as! LayoutAlign
		align.anchor = anchor
		align.content = content[0]
	}
}





class LayoutLayeredFactory: LayoutItemFactory {

	override func create() -> LayoutItem {
		return LayoutLayered()
	}

	override func apply(item: LayoutItem, _ content: [LayoutItem]) {
		let layered = item as! LayoutLayered
		layered.content = content
	}

}
