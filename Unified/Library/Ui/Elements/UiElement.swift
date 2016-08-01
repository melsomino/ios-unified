//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit





public struct SizeRange {
	public var min: CGSize
	public var max: CGSize

	public init(min: CGSize, max: CGSize) {
		self.min = min
		self.max = max
	}
	public static let zero = SizeRange(min: CGSizeZero, max: CGSizeZero)
}





public class UiElement {

	public final var definition: UiElementDefinition!
	public final var margin = UIEdgeInsetsZero
	public final var horizontalAlignment = UiAlignment.leading
	public final var verticalAlignment = UiAlignment.leading


	public final func measure(inBounds bounds: CGSize) -> CGSize {
		return expand(size: measureContent(inBounds: reduce(size: bounds)))
	}


	public final func layout(inBounds bounds: CGRect) {
		layoutContent(inBounds: reduce(rect: bounds))
	}


	public final func layout(inBounds bounds: CGRect, usingMeasured size: CGSize) {
		let aligned_frame = UiAlignment.alignedFrame(ofSize: size, inBounds: bounds, horizontalAlignment: horizontalAlignment, verticalAlignment: verticalAlignment)
		layout(inBounds: aligned_frame)
	}

	// MARK: - Overridable


	public var visible: Bool {
		return true
	}


	public func traversal(@noescape visit: (UiElement) -> Void) {
		visit(self)
	}


	public func bind(toModel values: [Any?]) {
	}


	public func measureContent(inBounds bounds: CGSize) -> CGSize {
		return bounds
	}


	public func layoutContent(inBounds bounds: CGRect) {
	}


	// MARK: - Internals


	private func reduce(size size: CGSize) -> CGSize {
		return CGSizeMake(size.width - margin.left - margin.right, size.height - margin.top - margin.bottom)
	}


	private func expand(size size: CGSize) -> CGSize {
		return CGSizeMake(size.width + margin.left + margin.right, size.height + margin.top + margin.bottom)
	}


	private func reduce(rect rect: CGRect) -> CGRect {
		return CGRectMake(
			rect.origin.x + margin.left,
			rect.origin.y + margin.top,
			rect.width - margin.left - margin.right,
			rect.height - margin.top - margin.bottom)
	}


	private func expand(rect rect: CGRect) -> CGRect {
		return CGRectMake(
			rect.origin.x - margin.left,
			rect.origin.y - margin.top,
			rect.width + margin.left + margin.right,
			rect.height + margin.top + margin.bottom)
	}
}





public class UiElementDefinition {

	public final var id: String?
	public final var childrenDefinitions = [UiElementDefinition]()
	public final var margin = UIEdgeInsetsZero
	public final var horizontalAlignment = UiAlignment.leading
	public final var verticalAlignment = UiAlignment.leading

	public static func register(name: String, definition: () -> UiElementDefinition) {
		definition_factory_by_name[name] = definition
	}

	public static func from(declaration element: DeclarationElement, context: DeclarationContext) throws -> UiElementDefinition {
		return try internal_from(declaration: element, context: context)
	}

	public final func traversal(@noescape visit: (UiElementDefinition) -> Void) {
		visit(self)
		for child_definition in childrenDefinitions {
			child_definition.traversal(visit)
		}
	}


	public init() {

	}


	// MARK: - Overridable


	public func applyDeclarationAttribute(attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		if attribute.name.hasPrefix("@") {
			id = attribute.name.substringFromIndex(attribute.name.startIndex.advancedBy(1))
		}
	}


	public func createElement() -> UiElement {
		return UiElement()
	}


	public func initialize(element: UiElement, children: [UiElement]) {
		element.definition = self
		element.margin = margin
		element.horizontalAlignment = horizontalAlignment
		element.verticalAlignment = verticalAlignment
	}


	// MARK: - Internals


	private static func internal_from(declaration element: DeclarationElement, context: DeclarationContext) throws -> UiElementDefinition {
		guard let definition_factory = UiElementDefinition.definition_factory_by_name[element.name] else {
			throw DeclarationError("Unknown layout element", element, context)
		}
		let definition = definition_factory()

		for index in 1 ..< element.attributes.count {
			let attribute = element.attributes[index]
			let isElementValue = index == 1 && attribute.value.isMissing
			switch attribute.name {
				case "margin":
					definition.margin = try context.getInsets(attribute)
				case "margin-top":
					definition.margin.top = try context.getFloat(attribute)
				case "margin-left":
					definition.margin.left = try context.getFloat(attribute)
				case "margin-bottom":
					definition.margin.bottom = try context.getFloat(attribute)
				case "margin-right":
					definition.margin.right = try context.getFloat(attribute)
				case "horizontal-alignment", "hor":
					definition.horizontalAlignment = try context.getEnum(attribute, UiAlignment.horizontal_names)
				case "vertical-alignment", "ver":
					definition.verticalAlignment = try context.getEnum(attribute, UiAlignment.vertical_names)
				default:
					try definition.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
			}
		}

		for child in element.children {
			definition.childrenDefinitions.append(try UiElementDefinition.from(declaration: child, context: context))
		}

		return definition
	}




	private static var definition_factory_by_name: [String:() -> UiElementDefinition] = [
		"vertical": {
			UiVerticalContainerDefinition()
		},
		"horizontal": {
			UiHorizontalContainerDefinition()
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
		},
		"decorator": {
			UiDecoratorDefinition()
		}
	]

}





