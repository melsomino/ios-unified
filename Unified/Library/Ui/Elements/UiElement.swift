//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit


public enum UiAlignment {
	case Fill, Leading, Tailing, Center
}


public class UiElement {

	public var id: String?

	public var visible: Bool {
		return true
	}

	public var fixedSize: Bool {
		return false
	}

	public func traversal(@noescape visit: (UiElement) -> Void) {
		visit(self)
	}

	public func measureMaxSize(bounds: CGSize) -> CGSize {
		return bounds
	}

	public func measureSize(bounds: CGSize) -> CGSize {
		return bounds
	}

	public func layout(bounds: CGRect) -> CGRect {
		return bounds
	}



}



public class UiElementFactory {
	var id: String?
	var childrenFactories = [UiElementFactory]()





	public func createWith(ui: Any) -> UiElement {
		return createWithMirror(Mirror(reflecting: ui))
	}





	public func createWithMirror(uiMirror: Mirror) -> UiElement {
		var content = [UiElement]()
		for factory in childrenFactories {
			content.append(factory.createWithMirror(uiMirror))
		}
		let item = findByIdInMirror(uiMirror) ?? create()
		initialize(item, content: content)
		return item
	}





	func findByIdInMirror(mirror: Mirror) -> UiElement? {
		if let id = id {
			for member in mirror.children {
				if let name = member.label {
					if name == id {
						return member.value as? UiElement
					}
				}
			}
		}
		return nil
	}





	func create() -> UiElement {
		return UiElement()
	}





	func initialize(item: UiElement, content: [UiElement]) {
		item.id = id
	}





	public static func fromDeclaration(element: DeclarationElement, context: DeclarationContext) throws -> UiElementFactory {
		var factory: UiElementFactory

		switch element.name {
			case "vertical":
				factory = UiStackContainerFactory(direction: .Vertical)
			case "horizontal":
				factory = UiStackContainerFactory(direction: .Horizontal)
			case "layered":
				factory = UiLayeredContainerFactory()
			case "view":
				factory = UiViewFactory()
			case "text":
				factory = UiTextFactory()
			case "image":
				factory = UiImageFactory()
			case "button":
				factory = UiButtonFactory()
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
					decorators.align.anchor = try context.getEnum(attribute, UiElementFactory.alignAnchors)
				default:
					try factory.applyDeclarationAttribute(attribute, context: context)
			}
		}

		for child in element.children {
			factory.childrenFactories.append(try UiElementFactory.fromDeclaration(child, context: context))
		}

		return decorators.result
	}





	static let alignments = [
		"fill": UiAlignment.Fill,
		"leading": UiAlignment.Leading,
		"tailing": UiAlignment.Tailing,
		"center": UiAlignment.Center
	]





	static let alignAnchors = [
		"top-left": UiAlignmentAnchor.TopLeft,
		"top": UiAlignmentAnchor.Top,
		"top-right": UiAlignmentAnchor.TopRight,
		"right": UiAlignmentAnchor.Right,
		"bottom-right": UiAlignmentAnchor.BottomRight,
		"bottom": UiAlignmentAnchor.Bottom,
		"bottom-left": UiAlignmentAnchor.BottomLeft,
		"left": UiAlignmentAnchor.Left,
		"center": UiAlignmentAnchor.Center
	]





	func applyDeclarationAttribute(attribute: DeclarationAttribute, context: DeclarationContext) throws {
		if attribute.name.hasPrefix("@") {
			id = attribute.name.substringFromIndex(attribute.name.startIndex.advancedBy(1))
		}
	}





	private struct Decorators {
		let target: UiElementFactory
		var first: UiElementFactory?
		var last: UiElementFactory?

		var cached_padding: UiPaddingContainerFactory?
		var cached_align: UiAlignmentContainerFactory?

		init(target: UiElementFactory) {
			self.target = target
		}

		var result: UiElementFactory {
			return first ?? target
		}

		var padding: UiPaddingContainerFactory {
			mutating get {
				if cached_padding == nil {
					cached_padding = UiPaddingContainerFactory()
					append(cached_padding!)
				}
				return cached_padding!
			}
		}

		var align: UiAlignmentContainerFactory {
			mutating get {
				if cached_align == nil {
					cached_align = UiAlignmentContainerFactory()
					append(cached_align!)
				}
				return cached_align!
			}
		}

		mutating func append(decorator: UiElementFactory) {
			decorator.childrenFactories.append(target)
			if last == nil {
				last = decorator
			}
			else {
				last!.childrenFactories[0] = decorator
			}
			first = decorator
		}
	}
}





