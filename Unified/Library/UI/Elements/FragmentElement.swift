//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit





public protocol FragmentElementDelegate: class {
	func tryExecuteAction(_ action: DynamicBindings.Expression?, defaultArgs: String?)



	func layoutChanged(forElement element: FragmentElement)
}





open class FragmentElement {

	public final weak var delegate: FragmentElementDelegate?
	public final var definition: FragmentElementDefinition!
	public final var margin = UIEdgeInsets.zero
	public final var horizontalAlignment = FragmentAlignment.leading
	public final var verticalAlignment = FragmentAlignment.leading
	public final var preserveSpace = false


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


	open var includeInLayout: Bool {
		return preserveSpace || visible
	}
	
	open var visible: Bool {
		return true
	}


	open func traversal(_ visit: (FragmentElement) -> Void) {
		visit(self)
	}



	open func bind(toModel values: [Any?]) {
	}



	open func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		return SizeMeasure(width: (0, bounds.width), height: bounds.height)
	}



	open func layoutContent(inBounds bounds: CGRect) {
	}


	// MARK: - Helpers


	open static func reduce(size: CGSize, edges: UIEdgeInsets) -> CGSize {
		return CGSize(width: size.width - edges.left - edges.right, height: size.height - edges.top - edges.bottom)
	}



	open static func expand(size: CGSize, edges: UIEdgeInsets) -> CGSize {
		return CGSize(width: size.width + edges.left + edges.right, height: size.height + edges.top + edges.bottom)
	}



	open static func reduce(rect: CGRect, edges: UIEdgeInsets) -> CGRect {
		return CGRect(
			x: rect.origin.x + edges.left,
			y: rect.origin.y + edges.top,
			width: rect.width - edges.left - edges.right,
			height: rect.height - edges.top - edges.bottom)
	}



	open static func expand(rect: CGRect, edges: UIEdgeInsets) -> CGRect {
		return CGRect(
			x: rect.origin.x - edges.left,
			y: rect.origin.y - edges.top,
			width: rect.width + edges.left + edges.right,
			height: rect.height + edges.top + edges.bottom)
	}



	open static func expand(measure size: SizeMeasure, edges: UIEdgeInsets) -> SizeMeasure {
		let hor = edges.left + edges.right
		let ver = edges.top + edges.bottom
		return SizeMeasure(width: (size.width.min + hor, size.width.max + hor), height: size.height + ver)
	}


}





open class FragmentElementDefinition {

	public final var id: String?
	public final var childrenDefinitions = [FragmentElementDefinition]()
	public final var margin = UIEdgeInsets.zero
	public final var horizontalAlignment = FragmentAlignment.leading
	public final var verticalAlignment = FragmentAlignment.leading
	public final var visible: DynamicBindings.Expression?
	public final var preserveSpace = false


	open static func register(_ name: String, definition: @escaping () -> FragmentElementDefinition) {
		definition_factory_by_name[name] = definition
	}



	open static func from(declaration element: DeclarationElement, context: DeclarationContext) throws -> FragmentElementDefinition {
		return try loadFrom(declaration: element, context: context)
	}



	public final func traversal(_ visit: (FragmentElementDefinition) -> Void) {
		visit(self)
		for child_definition in childrenDefinitions {
			child_definition.traversal(visit)
		}
	}



	public init() {

	}



	public final func boundHidden(_ values: [Any?]) -> Bool? {
		if let visible = visible {
			return !visible.evaluateBool(values)
		}
		return nil
	}

	// MARK: - Overridable


	open func applyDeclarationAttribute(_ attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		if attribute.name.hasPrefix("@") {
			id = attribute.name.substring(from: attribute.name.characters.index(attribute.name.startIndex, offsetBy: 1))
			return
		}
		switch attribute.name {
			case "horizontal-alignment", "hor":
				horizontalAlignment = try context.getEnum(attribute, FragmentAlignment.horizontal_names)
			case "vertical-alignment", "ver":
				verticalAlignment = try context.getEnum(attribute, FragmentAlignment.vertical_names)
			case "visible":
				visible = try context.getExpression(attribute)
			case "preserve-space":
				preserveSpace = try context.getBool(attribute)
			default:
				try context.applyInsets(&margin, name: "margin", attribute: attribute)
		}
	}



	open func applyDeclarationElement(_ element: DeclarationElement, context: DeclarationContext) throws -> Bool {
		return false
	}



	open func createElement() -> FragmentElement {
		return FragmentElement()
	}



	open func initialize(_ element: FragmentElement, children: [FragmentElement]) {
		element.definition = self
		element.margin = margin
		element.horizontalAlignment = horizontalAlignment
		element.verticalAlignment = verticalAlignment
		element.preserveSpace = preserveSpace
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





