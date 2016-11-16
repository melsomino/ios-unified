//
// Created by Власов М.Ю. on 11.11.16.
//

import Foundation
import UIKit


private func parse(element: DeclarationElement, startAttribute: Int,
	attributes: [String: (DeclarationAttribute) throws -> Void],
	children: [String: (DeclarationElement) throws -> Void]) throws {
	if attributes.count > 0 {
		for i in startAttribute ..< element.attributes.count {
			let attribute = element.attributes[i]
			if let parser = attributes[attribute.name] {
				try parser(attribute)
			}
		}
	}
	if children.count > 0 {
		for child in element.children {
			if let parser = children[child.name] {
				try parser(child)
			}
		}
	}
}



class ActionRouter {
	let action: String
	let args: String?
	weak var delegate: FragmentDelegate?

	init(action: DynamicBindings.Expression?, values: [Any?], delegate: FragmentDelegate) {
		if let (name, args) = Fragment.parse(action: action, values: values, defaultArgs: nil) {
			self.action = name
			self.args = args
			self.delegate = delegate
		}
		else {
			self.action = ""
			self.args = nil
			self.delegate = nil
		}
	}



	@objc func onAction() {
		delegate?.onAction(action, args: args)
	}
}



class FrameBarContext {
	let navigation: UINavigationItem
	let bar: UINavigationBar?
	let model: AnyObject
	let modelValues: [Any?]
	let delegate: FragmentDelegate
	let dependency: DependencyResolver
	let action = #selector(ActionRouter.onAction)
	var actions = [ActionRouter]()

	var optionalCentralUI: CentralUI? {
		return dependency.optional(CentralUIDependency)
	}

	var repository: Repository {
		return dependency.required(RepositoryDependency)
	}

	init(controller: UIViewController, model: AnyObject, bindings: DynamicBindings, delegate: FragmentDelegate, dependency: DependencyResolver) {
		self.delegate = delegate
		self.dependency = dependency

		navigation = controller.navigationItem
		bar = controller.navigationController?.navigationBar
		self.model = model
		var values = [Any?](repeating: nil, count: bindings.valueIndexByName.count)
		let mirror = Mirror(reflecting: model)
		for member in mirror.children {
			if let name = member.label {
				if let index = bindings.valueIndexByName[name] {
					values[index] = member.value
				}
			}
		}
		modelValues = values
	}



	func evaluate(_ expression: DynamicBindings.Expression?) -> String? {
		return expression?.evaluate(modelValues)
	}



	func target(action: DynamicBindings.Expression?) -> ActionRouter {
		let router = ActionRouter(action: action, values: modelValues, delegate: delegate)
		actions.append(router)
		return router
	}
}



class FrameBarItem {
	func create(context: FrameBarContext) -> UIBarButtonItem {
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
	override func create(context: FrameBarContext) -> UIBarButtonItem {
		if let centralUi = context.optionalCentralUI {
			return centralUi.createMenuIntegrationBarButtonItem()
		}
		return super.create(context: context)
	}
}



class FrameBarButtonItem: FrameBarItem {
	let action: DynamicBindings.Expression?
	let image: UIImage?
	let title: DynamicBindings.Expression?

	init(element: DeclarationElement, context: DeclarationContext) throws {
		var image: UIImage?
		var action: DynamicBindings.Expression?
		var title: DynamicBindings.Expression?
		for attribute in element.attributes[1 ..< element.attributes.count] {
			switch attribute.name {
				case "action":
					action = try context.getExpression(attribute)
				case "image":
					image = try context.getImage(attribute)
				case "title":
					title = try context.getExpression(attribute)
				default:
					break
			}
		}
		self.action = action
		self.image = image
		self.title = title
	}



	override func create(context: FrameBarContext) -> UIBarButtonItem {
		let target = context.target(action: action)
		if let image = image {
			return UIBarButtonItem(image: image, style: .plain, target: target, action: context.action)
		}
		return UIBarButtonItem(title: context.evaluate(title), style: .plain, target: target, action: context.action)
	}
}



class FrameBarFragmentItem: FrameBarItem {

	init(element: DeclarationElement, context: DeclarationContext) throws {
	}



	override func create(context: FrameBarContext) -> UIBarButtonItem {
		return UIBarButtonItem(barButtonSystemItem: .action, target: nil, action: nil)
	}
}



class FrameBarSystemItem: FrameBarItem {
	let systemItem: UIBarButtonSystemItem
	let action: DynamicBindings.Expression?

	init(element: DeclarationElement, context: DeclarationContext) throws {
		var systemItem: UIBarButtonSystemItem?
		var action: DynamicBindings.Expression?
		for attribute in element.attributes[1 ..< element.attributes.count] {
			if attribute.value.isMissing, let item = FrameBarSystemItem.systemItemByName[attribute.name] {
				systemItem = item
			}
			else if attribute.name == "action" {
				action = try context.getExpression(attribute)
			}
		}
		guard systemItem != nil else {
			throw DeclarationError("Invalid navigation bar item definition", element, context)
		}
		self.systemItem = systemItem!
		self.action = action
	}



	override func create(context: FrameBarContext) -> UIBarButtonItem {
		return UIBarButtonItem(barButtonSystemItem: systemItem, target: context.target(action: action), action: context.action)
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



class FrameBarTitle {
	func apply(context: FrameBarContext) {
	}



	static func from(element: DeclarationElement, context: DeclarationContext) throws -> FrameBarTitle {
		var text: DynamicBindings.Expression?
		var textAttributes = [String: Any]()
		var action: DynamicBindings.Expression?
		for attribute in element.attributes[1 ..< element.attributes.count] {
			switch attribute.name {
				case "text":
					guard let expression = try context.getExpression(attribute) else {
						throw DeclarationError("Invalid navigation bar title definition", attribute, context)
					}
					text = expression
				case "font":
					textAttributes[NSFontAttributeName] = try context.getFont(attribute, defaultFont: nil)
				case "color":
					textAttributes[NSForegroundColorAttributeName] = try context.getColor(attribute)
				case "action":
					action = try context.getExpression(attribute)
				default:
					break
			}
		}
		if let text = text {
			return FrameBarTitleText(text: text, attributes: textAttributes, action: action)
		}
		throw DeclarationError("Invalid navigation bar item definition", element, context)
	}
}



class FrameBarTitleText: FrameBarTitle {
	let text: DynamicBindings.Expression
	let attributes: [String: Any]?
	let action: DynamicBindings.Expression?

	init(text: DynamicBindings.Expression, attributes: [String: Any]?, action: DynamicBindings.Expression?) {
		self.text = text
		self.attributes = attributes
		self.action = action
	}



	override func apply(context: FrameBarContext) {
		guard let action = action else {
			context.navigation.title = text.evaluate(context.modelValues)
			context.bar?.titleTextAttributes = attributes
			return
		}

		let titleAttributes = attributes ?? UINavigationBar.appearance().titleTextAttributes
		let titleString = NSAttributedString(string: text.evaluate(context.modelValues) ?? "", attributes: titleAttributes)

		let titleView = UILabel()
		titleView.numberOfLines = 2
		titleView.attributedText = titleString
		titleView.textAlignment = .center
		let width = titleView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
		titleView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: 500))
		context.navigation.titleView = titleView

		let recognizer = UITapGestureRecognizer(target: context.target(action: action), action: context.action)
		titleView.isUserInteractionEnabled = true
		titleView.addGestureRecognizer(recognizer)
	}

	static let zero = FrameBarTitleText(text: DynamicBindings.Literal.zero, attributes: nil, action: nil)
}



class FrameBarTitleFragment: FrameBarTitle {
	init(element: DeclarationElement, context: DeclarationContext) throws {

	}



	override func apply(context: FrameBarContext) {
		super.apply(context: context)
	}
}



public class FrameNavigationBarDefinition {
	final let barTintColor: UIColor?
	final let tintColor: UIColor?
	final let translucent: Bool
	final let title: FrameBarTitle
	final let left: [FrameBarItem]
	final let right: [FrameBarItem]

	init(barTintColor: UIColor?, tintColor: UIColor?, translucent: Bool,
		title: FrameBarTitle, left: [FrameBarItem], right: [FrameBarItem]) {
		self.barTintColor = barTintColor
		self.tintColor = tintColor
		self.translucent = translucent
		self.title = title
		self.left = left
		self.right = right
	}



	static func items(from element: DeclarationElement, context: DeclarationContext) throws -> [FrameBarItem] {
		var items = [FrameBarItem]()
		for child in element.children {
			items.append(try FrameBarItem.from(element: child, context: context))
		}
		return items
	}



	public static func from(element: DeclarationElement, context: DeclarationContext) throws -> FrameNavigationBarDefinition {
		var barTintColor: UIColor?
		var tintColor: UIColor?
		var translucent = true
		var title: FrameBarTitle = FrameBarTitleText.zero
		var left = [FrameBarItem]()
		var right = [FrameBarItem]()
		try parse(element: element, startAttribute: 0, attributes: [
			"bar-tint-color": {
				barTintColor = try context.getColor($0)
			},
			"tint-color": {
				tintColor = try context.getColor($0)
			},
			"translucent": {
				translucent = try context.getBool($0)
			}
		], children: [
			"title": {
				title = try FrameBarTitle.from(element: $0, context: context)
			},
			"left": {
				left = try items(from: $0, context: context)
			},
			"right": {
				right = try items(from: $0, context: context)
			}
		])
		return FrameNavigationBarDefinition(barTintColor: barTintColor, tintColor: tintColor, translucent: translucent,
			title: title, left: left, right: right.reversed())
	}



	final func apply(context: FrameBarContext) {
		if let bar = context.bar {
			bar.barTintColor = barTintColor
			bar.tintColor = tintColor
			bar.isTranslucent = translucent
			title.apply(context: context)
		}
		var items = [UIBarButtonItem]()
		for factory in left {
			items.append(factory.create(context: context))
		}
		context.navigation.setLeftBarButtonItems(items, animated: false)
		items.removeAll()
		for factory in right {
			items.append(factory.create(context: context))
		}
		context.navigation.setRightBarButtonItems(items, animated: false)
	}

	public static let zero = FrameNavigationBarDefinition(barTintColor: nil, tintColor: nil, translucent: true,
		title: FrameBarTitleText.zero, left: [], right: [])
}



public class FrameDefinition {
	public static let zero = FrameDefinition(bindings: DynamicBindings(), backgroundColor: .white, statusBar: .default, navigationBar: FrameNavigationBarDefinition.zero)

	public static let RepositorySection = "ui-frame"

	public final let bindings: DynamicBindings
	public final let navigationBar: FrameNavigationBarDefinition
	public final let backgroundColor: UIColor
	public final let statusBar: UIStatusBarStyle

	init(bindings: DynamicBindings, backgroundColor: UIColor, statusBar: UIStatusBarStyle, navigationBar: FrameNavigationBarDefinition) {
		self.bindings = bindings
		self.backgroundColor = backgroundColor
		self.statusBar = statusBar
		self.navigationBar = navigationBar
	}



	public static func from(element: DeclarationElement, startAttribute: Int, context: DeclarationContext) throws -> FrameDefinition {
		var navigationBar = FrameNavigationBarDefinition.zero
		var backgroundColor = UIColor.clear
		var statusBar = UIStatusBarStyle.default
		try parse(element: element, startAttribute: startAttribute,
			attributes: [
				"background-color": {
					backgroundColor = try context.getColor($0)
				},
				"status-bar": {
					statusBar = try context.getEnum($0, FrameDefinition.statusBarByName)
				}
			],
			children: [
				"navigation-bar": {
					navigationBar = try FrameNavigationBarDefinition.from(element: $0, context: context)
				}
			]
		)
		return FrameDefinition(bindings: context.bindings, backgroundColor: backgroundColor, statusBar: statusBar,
			navigationBar: navigationBar)
	}


	static let statusBarByName: [String: UIStatusBarStyle] = [
		"dark": .default,
		"default": .default,
		"light": .lightContent
	]


	final func apply(controller: UIViewController, model: AnyObject, delegate: FragmentDelegate, dependency: DependencyResolver) -> [ActionRouter] {
		let context = FrameBarContext(controller: controller, model: model, bindings: bindings, delegate: delegate, dependency: dependency)
		navigationBar.apply(context: context)
		return context.actions
	}



	static func setup() {
		DefaultRepository.register(section: RepositorySection) {
			element, startAttribute, context in
			return (element.attributes[startAttribute].name, try FrameDefinition.from(element: element, startAttribute: startAttribute, context: context))
		}
	}
}



