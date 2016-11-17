//
// Created by Власов М.Ю. on 17.11.16.
//

import Foundation



class FragmentAction {
	func execute(element: FragmentElement) {
	}

	static func from(element: DeclarationElement, context: DeclarationContext) throws -> FragmentAction {
		for attribute in element.skipName {
			switch attribute.name {
				case "popover":
					return try FragmentActionPopover(element: element, context: context)
				default:
					break
			}
		}
		throw DeclarationError("Invalid action definition", element, context)
	}
}



class FragmentActionNameArgs: FragmentAction {
	let expression: DynamicBindings.Expression

	init(expression: DynamicBindings.Expression) {
		self.expression = expression
	}



	override func execute(element: FragmentElement) {
	}
}



enum PopoverAppearance {
	case modal
	case screenCenter
	case screenSide(UIRectEdge)
	case element(UIRectEdge)
}



class FragmentActionPopover: FragmentAction {
	let fragmentDefinition: FragmentDefinition
	let appearance: PopoverAppearance

	init(element: DeclarationElement, context: DeclarationContext) throws {
		var appearance = PopoverAppearance.screenCenter
		for attribute in element.attributes[0 ..< element.attributes.count] {
			switch attribute.name {
				case "popover":
					appearance = try context.getEnum(attribute, FragmentActionPopover.appearanceByName)
				default:
					break
			}
		}
		fragmentDefinition = try FragmentDefinition.from(element: element, startAttribute: 0, context: context)
		self.appearance = appearance
	}


	private static let appearanceByName: [String: PopoverAppearance] = [
		"modal": .modal,
		"screen-center": .screenCenter,
		"screen-left": .screenSide(.left),
		"screen-right": .screenSide(.right),
		"screen-top": .screenSide(.top),
		"screen-bottom": .screenSide(.bottom),
		"element-left": .element(.left),
		"element-right": .element(.right),
		"element-top": .element(.top),
		"element-bottom": .element(.bottom)
	]

	override func execute(element: FragmentElement) {
		guard let parent = element.fragment else {
			return
		}
		let fragment = Fragment(definition: fragmentDefinition, dependency: parent.dependency)
		fragment.model = parent.model
	}
}



