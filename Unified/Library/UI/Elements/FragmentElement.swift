//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit





public protocol FragmentElementDelegate: class {
	func tryExecuteAction(action: DynamicBindings.Expression?)



	func layoutChanged(forElement element: FragmentElement)
}





public class FragmentElement {

	public final weak var delegate: FragmentElementDelegate?
	public final var definition: FragmentElementDefinition!
	public final var margin = UIEdgeInsetsZero
	public final var horizontalAlignment = FragmentAlignment.leading
	public final var verticalAlignment = FragmentAlignment.leading


	public final func measure(inBounds bounds: CGSize) -> SizeMeasure {
		let contentMeasure = measureContent(inBounds: FragmentElement.reduce(size: bounds, edges: margin))
		return FragmentElement.expand(measure: contentMeasure, edges: margin)
	}



	public final func layout(inBounds bounds: CGRect) {
		layoutContent(inBounds: FragmentElement.reduce(rect: bounds, edges: margin))
	}



	public final func layout(inBounds bounds: CGRect, usingMeasured size: CGSize) {
		let aligned_frame = FragmentAlignment.alignedFrame(ofSize: size, inBounds: bounds, horizontalAlignment: horizontalAlignment, verticalAlignment: verticalAlignment)
		layout(inBounds: aligned_frame)
	}





	// MARK: - Overridable


	public var visible: Bool {
		return true
	}


	public func traversal(@noescape visit: (FragmentElement) -> Void) {
		visit(self)
	}



	public func bind(toModel values: [Any?]) {
	}



	public func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		return SizeMeasure(width: (0, bounds.width), height: bounds.height)
	}



	public func layoutContent(inBounds bounds: CGRect) {
	}


	// MARK: - Helpers


	public static func reduce(size size: CGSize, edges: UIEdgeInsets) -> CGSize {
		return CGSizeMake(size.width - edges.left - edges.right, size.height - edges.top - edges.bottom)
	}



	public static func expand(size size: CGSize, edges: UIEdgeInsets) -> CGSize {
		return CGSizeMake(size.width + edges.left + edges.right, size.height + edges.top + edges.bottom)
	}



	public static func reduce(rect rect: CGRect, edges: UIEdgeInsets) -> CGRect {
		return CGRectMake(
			rect.origin.x + edges.left,
			rect.origin.y + edges.top,
			rect.width - edges.left - edges.right,
			rect.height - edges.top - edges.bottom)
	}



	public static func expand(rect rect: CGRect, edges: UIEdgeInsets) -> CGRect {
		return CGRectMake(
			rect.origin.x - edges.left,
			rect.origin.y - edges.top,
			rect.width + edges.left + edges.right,
			rect.height + edges.top + edges.bottom)
	}



	public static func expand(measure size: SizeMeasure, edges: UIEdgeInsets) -> SizeMeasure {
		let hor = edges.left + edges.right
		let ver = edges.top + edges.bottom
		return SizeMeasure(width: (size.width.min + hor, size.width.max + hor), height: size.height + ver)
	}


}





public class FragmentElementDefinition {

	public final var id: String?
	public final var childrenDefinitions = [FragmentElementDefinition]()
	public final var margin = UIEdgeInsetsZero
	public final var horizontalAlignment = FragmentAlignment.leading
	public final var verticalAlignment = FragmentAlignment.leading
	public final var visible: DynamicBindings.Expression?


	public static func register(name: String, definition: () -> FragmentElementDefinition) {
		definition_factory_by_name[name] = definition
	}



	public static func from(declaration element: DeclarationElement, context: DeclarationContext) throws -> FragmentElementDefinition {
		return try loadFrom(declaration: element, context: context)
	}



	public final func traversal(@noescape visit: (FragmentElementDefinition) -> Void) {
		visit(self)
		for child_definition in childrenDefinitions {
			child_definition.traversal(visit)
		}
	}



	public init() {

	}



	public final func boundHidden(values: [Any?]) -> Bool? {
		if let visible = visible {
			return !visible.evaluateBool(values)
		}
		return nil
	}

	// MARK: - Overridable


	public func applyDeclarationAttribute(attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		if attribute.name.hasPrefix("@") {
			id = attribute.name.substringFromIndex(attribute.name.startIndex.advancedBy(1))
			return
		}
		switch attribute.name {
			case "horizontal-alignment", "hor":
				horizontalAlignment = try context.getEnum(attribute, FragmentAlignment.horizontal_names)
			case "vertical-alignment", "ver":
				verticalAlignment = try context.getEnum(attribute, FragmentAlignment.vertical_names)
			case "visible":
				visible = try context.getExpression(attribute)
			default:
				try context.applyInsets(&margin, name: "margin", attribute: attribute)
		}
	}



	public func applyDeclarationElement(element: DeclarationElement, context: DeclarationContext) throws -> Bool {
		return false
	}



	public func createElement() -> FragmentElement {
		return FragmentElement()
	}



	public func initialize(element: FragmentElement, children: [FragmentElement]) {
		element.definition = self
		element.margin = margin
		element.horizontalAlignment = horizontalAlignment
		element.verticalAlignment = verticalAlignment
	}


	// MARK: - Internals


	private static func loadFrom(declaration element: DeclarationElement, context: DeclarationContext) throws -> FragmentElementDefinition {
		guard let definition_factory = FragmentElementDefinition.definition_factory_by_name[element.name] else {
			throw DeclarationError("Unknown layout element", element, context)
		}
		let definition = definition_factory()

		for index in 1 ..< element.attributes.count {
			let attribute = element.attributes[index]
			let isElementValue = index == 1 && attribute.value.isMissing
			try definition.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
		}

		for child in element.children {
			if try definition.applyDeclarationElement(child, context: context) {
			}
			else {
				definition.childrenDefinitions.append(try FragmentElementDefinition.from(declaration: child, context: context))
			}
		}

		return definition
	}


	private static var definition_factory_by_name: [String:() -> FragmentElementDefinition] = [
		"vertical": {
			VerticalContainerDefinition()
		},
		"horizontal": {
			HorizontalContainerDefinition()
		},
		"layered": {
			LayeredContainerDefinition()
		},
		"view": {
			ViewElementDefinition()
		},
		"text": {
			TextElementDefinition()
		},
		"html": {
			HtmlElementDefinition()
		},
		"image": {
			ImageElementDefinition()
		},
		"button": {
			ButtonElementDefinition()
		},
		"decorator": {
			DecoratorElementDefinition()
		},
		"picker": {
			PickerElementDefinition()
		},
		"edit": {
			TextEditDefinition()
		}
	]

}





