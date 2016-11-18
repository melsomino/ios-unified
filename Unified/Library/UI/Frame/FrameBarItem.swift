//
// Created by Власов М.Ю. on 16.11.16.
//

import Foundation
import UIKit


class FrameBarItem {
	func create(frame: FrameBuilder) -> UIBarButtonItem {
		return UIBarButtonItem()
	}



	static func from(element: DeclarationElement, context: DeclarationContext) throws -> FrameBarItem {
		switch element.name {
			case "menu":
				return FrameBarMenuItem()
			case "system":
				return try FrameBarSystemItem(element: element, context: context)
			case "button":
				return try FrameBarButtonItem(element: element, context: context)
			case "fragment":
				return try FrameBarFragmentItem(element: element, context: context)
			default:
				break
		}
		throw DeclarationError("Invalid navigation bar item definition", element, context)
	}
}



class FrameBarMenuItem: FrameBarItem {
	override func create(frame: FrameBuilder) -> UIBarButtonItem {
		if let centralUi = frame.optionalCentralUI {
			return centralUi.createMenuIntegrationBarButtonItem()
		}
		return super.create(frame: frame)
	}
}



class FrameBarButtonItem: FrameBarItem {
	let action: FragmentAction?
	let image: UIImage?
	let title: DynamicBindings.Expression?

	init(element: DeclarationElement, context: DeclarationContext) throws {
		var image: UIImage?
		var title: DynamicBindings.Expression?
		for attribute in element.skipName {
			switch attribute.name {
				case "image":
					image = try context.getImage(attribute)
				case "title":
					title = try context.getExpression(attribute)
				default:
					break
			}
		}
		self.action = try FragmentAction.from(element: element, context: context)
		self.image = image
		self.title = title
	}



	override func create(frame: FrameBuilder) -> UIBarButtonItem {
		let target = frame.actionRouter(action)
		if let image = image {
			return UIBarButtonItem(image: image, style: .plain, target: target, action: #selector(ActionRouter.onAction))
		}
		return UIBarButtonItem(title: frame.evaluate(title), style: .plain, target: target, action: #selector(ActionRouter.onAction))
	}
}



class FrameBarFragmentItem: FrameBarItem {
	let action: FragmentAction?
	let fragmentDefinition: FragmentDefinition

	init(element: DeclarationElement, context: DeclarationContext) throws {
		action = try FragmentAction.from(element: element, context: context)
		fragmentDefinition = try FragmentDefinition.from(element: element, startAttribute: 0, context: context)
	}



	override func create(frame: FrameBuilder) -> UIBarButtonItem {
		let actor = frame.fragmentActor(definition: fragmentDefinition, createContainer: true, measureInWidth: 320)

		if let action = action, let container = actor.container {
			let recognizer = UITapGestureRecognizer(target: frame.actionRouter(action), action: #selector(ActionRouter.onAction))
			container.isUserInteractionEnabled = true
			container.addGestureRecognizer(recognizer)
		}
		return UIBarButtonItem(customView: actor.container!)
	}
}



class FrameBarSystemItem: FrameBarItem {
	let systemItem: UIBarButtonSystemItem
	let action: FragmentAction?

	init(element: DeclarationElement, context: DeclarationContext) throws {
		self.systemItem = try context.getEnum(element.attributes[0], FrameBarSystemItem.systemItemByName)
		self.action = try FragmentAction.from(element: element, context: context)
	}



	override func create(frame: FrameBuilder) -> UIBarButtonItem {
		return UIBarButtonItem(barButtonSystemItem: systemItem, target: frame.actionRouter(action), action: #selector(ActionRouter.onAction))
	}



	static let systemItemByName: [String: UIBarButtonSystemItem] = [
		"done": .done,
		"cancel": .cancel,
		"edit": .edit,
		"save": .save,
		"add": .add,
		"flexible-space": .flexibleSpace,
		"fixed-space": .fixedSpace,
		"compose": .compose,
		"reply": .reply,
		"action": .action,
		"organize": .organize,
		"bookmarks": .bookmarks,
		"search": .search,
		"refresh": .refresh,
		"stop": .stop,
		"camera": .camera,
		"trash": .trash,
		"play": .play,
		"pause": .pause,
		"rewind": .rewind,
		"fast-forward": .fastForward,
		"undo": .undo,
		"redo": .redo,
		"page-curl": .pageCurl,
	]
}

