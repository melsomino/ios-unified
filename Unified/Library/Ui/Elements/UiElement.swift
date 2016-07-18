//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit





public class UiElement {

	public final var definition: UiElementDefinition!


	// MARK: - Overridable


	public var visible: Bool {
		return true
	}

	public var fixedSize: Bool {
		return false
	}

	public func traversal(@noescape visit: (UiElement) -> Void) {
		visit(self)
	}

	public func bind(toModel values: [Any?]) {
	}


	public func measureSizeRange(bounds: CGSize) -> UiSizeRange {
		return UiSizeRange.fromSize(bounds)
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





public class UiElementDefinition {

	public final var id: String?
	public final var childrenDefinitions = [UiElementDefinition]()

	public init() {

	}



	public static func register(name: String, definition: () -> UiElementDefinition) {
		definitionFactoryByName[name] = definition
	}


	public final func traversal(@noescape visit: (UiElementDefinition) -> Void) {
		visit(self)
		for childDefinition in childrenDefinitions {
			childDefinition.traversal(visit)
		}
	}


	// MARK: - Virtuals


	public func applyDeclarationAttribute(attribute: DeclarationAttribute, context: DeclarationContext) throws {
		if attribute.name.hasPrefix("@") {
			id = attribute.name.substringFromIndex(attribute.name.startIndex.advancedBy(1))
		}
	}


	public func createElement() -> UiElement {
		return UiElement()
	}


	public func initialize(element: UiElement, children: [UiElement]) {
		element.definition = self
	}


	// MARK: - Internals


	public static func fromDeclaration(element: DeclarationElement, context: DeclarationContext) throws -> UiElementDefinition {
		guard let createFactory = UiElementDefinition.definitionFactoryByName[element.name] else {
			throw DeclarationError(message: "Unknown markup element \"\(element.name)\"", scanner: nil)
		}
		let factory = createFactory()

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
					decorators.align.anchor = try context.getEnum(attribute, UiElementDefinition.alignAnchors)
				default:
					try factory.applyDeclarationAttribute(attribute, context: context)
			}
		}

		for child in element.children {
			factory.childrenDefinitions.append(try UiElementDefinition.fromDeclaration(child, context: context))
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







	private struct Decorators {
		let target: UiElementDefinition
		var first: UiElementDefinition?
		var last: UiElementDefinition?

		var cached_padding: UiPaddingContainerDefinition?
		var cached_align: UiAlignmentContainerFactory?

		init(target: UiElementDefinition) {
			self.target = target
		}

		var result: UiElementDefinition {
			return first ?? target
		}

		var padding: UiPaddingContainerDefinition {
			mutating get {
				if cached_padding == nil {
					cached_padding = UiPaddingContainerDefinition()
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

		mutating func append(decorator: UiElementDefinition) {
			decorator.childrenDefinitions.append(target)
			if last == nil {
				last = decorator
			}
			else {
				last!.childrenDefinitions[0] = decorator
			}
			first = decorator
		}
	}





	public static var definitionFactoryByName: [String:() -> UiElementDefinition] = [
		"vertical": {
			UiStackContainerDefinition(direction: .Vertical)
		},
		"horizontal": {
			UiStackContainerDefinition(direction: .Horizontal)
		},
		"layered": {
			UiLayeredContainerDefinition()
		},
		"view": {
			UiViewDefinition()
		},
		"text": {
			UiTextDefinition()
		},
		"html": {
			UiHtmlDefinition()
		},
		"image": {
			UiImageDefinition()
		},
		"button": {
			UiButtonDefinition()
		}
	]

}





