//
// Created by Власов М.Ю. on 11.11.16.
//

import Foundation
import UIKit


func parse(element: DeclarationElement, startAttribute: Int,
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



class FrameBuilder {
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
		let frame = FrameBuilder(controller: controller, model: model, bindings: bindings, delegate: delegate, dependency: dependency)
		navigationBar.apply(frame: frame)
		return frame.actions
	}



	static func setup() {
		DefaultRepository.register(section: RepositorySection) {
			element, startAttribute, context in
			return (element.attributes[startAttribute].name, try FrameDefinition.from(element: element, startAttribute: startAttribute, context: context))
		}
	}
}



