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
	public final var valign = UiAlignment.Leading
	public final var halign = UiAlignment.Leading


	public final func measure(inBounds bounds: CGSize) -> SizeRange {
		let sizeRange = measureContent(inBounds: reduce(size: bounds))
		return SizeRange(min: expand(size: sizeRange.min), max: expand(size: sizeRange.max))
	}


	public final func layout(inBounds bounds: CGRect) -> CGRect {
		let contentFrame = layoutContent(inBounds: reduce(rect: bounds))
		return expand(rect: contentFrame)
	}


	public final func align(withSize size: CGSize, inBounds bounds: CGRect) -> CGRect {
		return layout(inBounds: UiElement.layout(size: size, inBounds: bounds, halign: halign, valign: valign))
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


	public func measureContent(inBounds bounds: CGSize) -> SizeRange {
		return SizeRange(min: CGSizeZero, max: bounds)
	}


	public func layoutContent(inBounds bounds: CGRect) -> CGRect {
		return bounds
	}


	// MARK: - Utility


	public static func layout(size size: CGSize, inBounds bounds: CGRect, halign: UiAlignment, valign: UiAlignment) -> CGRect {
		var frame = CGRect(origin: bounds.origin, size: size)
		switch halign {
			case .Center:
				frame.origin.x = bounds.origin.x + bounds.size.width / 2 - size.width / 2
			case .Tailing:
				frame.origin.x = bounds.origin.x + bounds.size.width - size.width
			case .Fill:
				frame.size.width = bounds.width
			default:
				break
		}
		switch valign {
			case .Center:
				frame.origin.y = bounds.origin.y + bounds.size.height / 2 - size.height / 2
			case .Tailing:
				frame.origin.y = bounds.origin.y + bounds.size.height - size.height
			case .Fill:
				frame.size.height = bounds.height
			default:
				break
		}
		return frame
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
	public final var halign = UiAlignment.Leading
	public final var valign = UiAlignment.Leading

	public static func register(name: String, definition: () -> UiElementDefinition) {
		definitionFactoryByName[name] = definition
	}


	public final func traversal(@noescape visit: (UiElementDefinition) -> Void) {
		visit(self)
		for childDefinition in childrenDefinitions {
			childDefinition.traversal(visit)
		}
	}


	public init() {

	}


	// MARK: - Overridable


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
		element.margin = margin
		element.halign = halign
		element.valign = valign
	}


	// MARK: - Internals


	public static func fromDeclaration(element: DeclarationElement, context: DeclarationContext) throws -> UiElementDefinition {
		guard let definitionFactory = UiElementDefinition.definitionFactoryByName[element.name] else {
			throw DeclarationError(message: "Unknown layout element \"\(element.name)\"", scanner: nil)
		}
		let definition = definitionFactory()

		for index in 1 ..< element.attributes.count {
			let attribute = element.attributes[index]
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
				case "halign":
					definition.halign = try context.getEnum(attribute, UiElementDefinition.alignments)
				case "valign":
					definition.valign = try context.getEnum(attribute, UiElementDefinition.alignments)
				default:
					try definition.applyDeclarationAttribute(attribute, context: context)
			}
		}

		for child in element.children {
			definition.childrenDefinitions.append(try UiElementDefinition.fromDeclaration(child, context: context))
		}

		return definition
	}



	static let alignments = [
		"fill": UiAlignment.Fill,
		"leading": UiAlignment.Leading,
		"tailing": UiAlignment.Tailing,
		"center": UiAlignment.Center
	]



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





