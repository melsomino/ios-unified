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



class FrameActor {

}



class ActionRouter: FrameActor {
	let action: FragmentAction?
	var context: FragmentActionContext

	init(action: FragmentAction?, context: FragmentActionContext) {
		self.action = action
		self.context = context
	}



	@objc func onAction() {
		action?.execute(context: context)
	}
}



class FragmentActor: FrameActor {
	let fragment: Fragment
	let container: FragmentContainer?
	init(fragment: Fragment, container: FragmentContainer?) {
		self.fragment = fragment
		self.container = container
	}
}




class FrameBuilder {
	let navigation: UINavigationItem
	let bar: UINavigationBar?
	let model: AnyObject
	let modelValues: [Any?]
	let delegate: FragmentDelegate
	let dependency: DependencyResolver
	var actors = [FrameActor]()

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



	func actionRouter(_ action: FragmentAction?) -> FrameActor {
		let router = ActionRouter(action: action,
			context: FragmentActionContext(dependency: dependency, delegate: delegate, model: model, modelValues: modelValues, reasonElement: nil))
		actors.append(router)
		return router
	}



	func fragmentActor(definition: FragmentDefinition, createContainer: Bool, measureInWidth: CGFloat) -> FragmentActor {
		let fragment = Fragment(forModelType: AnyObject.self)
		fragment.dependency = dependency
		fragment.definition = definition
		fragment.model = model
		fragment.delegate = delegate
		var fragmentContainer: FragmentContainer?
		if createContainer {
			fragment.performLayoutInWidth = false
			let container = FragmentContainer()
			let size = fragment.rootElement!.measure(inBounds: CGSize(width: measureInWidth, height: 0)).maxSize
			container.frame = CGRect(x:0, y:0, width: size.width, height: size.height)
			fragment.container = container
			container.fragment = fragment
			fragmentContainer = container
		}
		return FragmentActor(fragment: fragment, container: fragmentContainer)
	}
}





public class FrameDefinition {
	public static let zero = FrameDefinition(bindings: DynamicBindings(), backgroundColor: .white, statusBar: .default, navigationBar: FrameNavigationBarDefinition.zero)


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


	final func apply(controller: UIViewController, model: AnyObject, delegate: FragmentDelegate, dependency: DependencyResolver) throws -> [FrameActor] {
		let frame = FrameBuilder(controller: controller, model: model, bindings: bindings, delegate: delegate, dependency: dependency)
		try navigationBar.apply(frame: frame)
		return frame.actors
	}


	public static let RepositorySection = "frame"

	static func createFromRepository(_ element: DeclarationElement, _ startAttribute: Int, _ context: DeclarationContext) throws -> (String, AnyObject) {
		let name = element.attributes[startAttribute].name
		let definition = try FrameDefinition.from(element: element, startAttribute: startAttribute, context: context)
		return (name, definition)
	}



	static func setup() {
		DefaultRepository.register(section: RepositorySection, itemFactory: createFromRepository)
	}
}



