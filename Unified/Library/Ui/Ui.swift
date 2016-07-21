//
// Created by Michael Vlasov on 27.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit


public protocol UiDelegate: class {
	func onAction(action: String, args: String?)
}


public class Ui: RepositoryDependent, RepositoryListener {

	public let modelType: Any.Type
	public var layoutCacheKeyProvider: ((Any) -> String?)?
	public var performLayoutInWidth = false

	public var definition: UiDefinition! {
		definitionRequired()
		return currentDefinition
	}

	private var currentDefinition: UiDefinition?
	private func definitionRequired() {
		if currentDefinition == nil {
			updateDefinitionFromRepository()
		}
	}

	public weak var delegate: UiDelegate?

	private var layoutName: String? {
		didSet {
			updateDefinitionFromRepository()
		}
	}

	public var layoutCache: UiLayoutCache?

	public var container: UIView? {
		didSet {
			detachFromContainer()
			attachToContainer()
		}
	}

	public var model: Any? {
		didSet {
			definitionRequired()
			if modelValues.count > 0 {
				for i in 0 ..< modelValues.count {
					modelValues[i] = nil
				}
				if let model = model {
					let mirror = Mirror(reflecting: model)
					for member in mirror.children {
						if let name = member.label {
							if let index = currentDefinition!.bindings.valueIndexByName[name] {
								modelValues[index] = member.value
							}
						}
					}
				}
			}
			if currentDefinition!.hasBindings {
				rootElement?.traversal {
					$0.bind(toModel: modelValues)
				}
			}
			onModelChanged()
			performLayout()
		}
	}


	public init(forModelType modelType: Any.Type) {
		self.modelType = modelType
	}


	public func heightFor(model: Any, inWidth width: CGFloat) -> CGFloat {
		let layoutCacheKey = getLayoutCacheKey(forModel: model)
		if layoutCacheKey != nil {
			if let frames = layoutCache!.cachedFramesForWidth(width, key: layoutCacheKey!) {
				return frames[0].height
			}
		}

		self.model = model
		performLayout(inWidth: width)
		return frame.height
	}


	public func performLayout() {
		if let bounds = container?.bounds.size {
			if performLayoutInWidth {
				performLayout(inWidth: bounds.width)
			}
			else {
				performLayout(inBounds: bounds)
			}
		}
	}


	public func performLayout(inWidth width: CGFloat) {
		let layoutCacheKey = resolveLayoutCacheKey(forModel: model)
		if layoutCacheKey != nil {
			if let frames = layoutCache!.cachedFramesForWidth(width, key: layoutCacheKey!) {
				frame = frames[0]
				for index in 0 ..< min(frames.count - 1, contentElements.count) {
					contentElements[index].frame = frames[index + 1]
				}
				return
			}
		}

		performLayout(inBounds: CGSizeMake(width, 10000))

		if layoutCacheKey != nil {
			var frames = [CGRect](count: 1 + contentElements.count, repeatedValue: CGRectZero)
			frames[0] = frame
			for index in 0 ..< contentElements.count {
				frames[index + 1] = contentElements[index].frame
			}
			layoutCache!.setFrames(frames, forWidth: width, key: layoutCacheKey!)
		}
	}


	public func performLayout(inBounds bounds: CGSize) {
		definitionRequired()
		rootElement!.measureMaxSize(bounds)
		rootElement!.measureSize(bounds)
		frame = rootElement!.layout(CGRectMake(0, 0, bounds.width, bounds.height))

		print("perform layout")
	}

	public private(set) var frame = CGRectZero


	public func tryExecuteAction(action: UiBindings.Expression?) {
		guard let actionWithArgs = action?.evaluate(modelValues) else {
			return
		}
		var name: String
		var args: String?
		if let argsSeparator = actionWithArgs.rangeOfCharacterFromSet(NSCharacterSet.whitespaceCharacterSet()) {
			name = actionWithArgs.substringToIndex(argsSeparator.startIndex)
			args = actionWithArgs.substringFromIndex(argsSeparator.endIndex).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
			if args!.isEmpty {
				args = nil
			}
		}
		else {
			name = actionWithArgs
		}
		delegate?.onAction(name, args: args)
	}


	// MARK: - Virtuals


	public func onModelChanged() {
	}


	public func getLayoutCacheKey(forModel model: Any) -> String? {
		definitionRequired()
		guard let keyProvider = currentDefinition!.layoutCacheKey, definition = currentDefinition else {
			return nil
		}
		var values = [Any?](count: definition.bindings.valueIndexByName.count, repeatedValue: nil)
		let mirror = Mirror(reflecting: model)
		for member in mirror.children {
			if let name = member.label {
				if let index = definition.bindings.valueIndexByName[name] {
					values[index] = member.value
				}
			}
		}
		return keyProvider.evaluate(values)
	}


	// MARK: - RepositoryListener


	public func repositoryChanged(repository: Repository) {
		updateDefinitionFromRepository()
	}


	// MARK: - Dependency


	public var dependency: DependencyResolver! {
		didSet {
			oldValue?.optional(RepositoryDependency)?.removeListener(self)
			optionalRepository?.addListener(self)
		}
	}


	// MARK: - Internals


	private var rootElement: UiElement!
	private var contentElements = [UiContentElement]()
	private var modelValues = [Any?]()

	private func resolveLayoutCacheKey(forModel model: Any?) -> String? {
		guard let model = model else {
			return nil
		}
		return getLayoutCacheKey(forModel: model)
	}

	private func setDefinition(definition: UiDefinition?) {
		guard !sameObjects(definition, self.currentDefinition) else {
			return
		}

		self.currentDefinition = definition

		detachFromContainer()

		rootElement = definition?.createRootElement(forUi: self)
		contentElements.removeAll(keepCapacity: true)
		rootElement.traversal {
			dependency.resolve($0)
			if let element = $0 as? UiContentElement {
				contentElements.append(element)
			}
		}
		modelValues = [Any?](count: definition?.bindings.valueIndexByName.count ?? 0, repeatedValue: nil)

		attachToContainer()

		performLayout()
	}


	func updateDefinitionFromRepository() {
		setDefinition(try! repository.uiFactory(forModelType: modelType, name: layoutName))
	}


	private func detachFromContainer() {
		for element in contentElements {
			element.view?.removeFromSuperview()
		}
	}


	private func attachToContainer() {
		guard let container = container else {
			return
		}
		for element in contentElements {
			if element.view == nil {
				element.view = element.createView()
				element.onViewCreated()
				element.initializeView()
			}
			container.addSubview(element.view)
		}
		initializeContainer()
	}


	private func initializeContainer() {
		container?.backgroundColor = currentDefinition?.containerBackgroundColor
		container?.layer.cornerRadius = currentDefinition?.containerCornerRadius ?? 0
		if currentDefinition?.containerCornerRadius != nil {
			container?.clipsToBounds = true
		}
	}


	private func same(a: String?, _ b: String?) -> Bool {
		if a == nil && b == nil {
			return true
		}
		if a == nil || b == nil {
			return false
		}
		return a! == b!
	}


	private func sameObjects(a: AnyObject?, _ b: AnyObject?) -> Bool {
		if a == nil && b == nil {
			return true
		}
		if a == nil || b == nil {
			return false
		}
		return a! === b!
	}
}





public class UiDefinition {
	private let rootElementDefinition: UiElementDefinition
	let bindings: UiBindings
	let hasBindings: Bool
	private let ids: Set<String>

	public let selectAction: UiBindings.Expression?
	public let layoutCacheKey: UiBindings.Expression?

	let containerBackgroundColor: UIColor?
	let containerCornerRadius: CGFloat?

	init(rootElementDefinition: UiElementDefinition,
		bindings: UiBindings,
		hasBindings: Bool,
		ids: Set<String>,
		selectAction: UiBindings.Expression?,
		layoutCacheKey: UiBindings.Expression?,
		containerBackgroundColor: UIColor?,
		containerCornerRadius: CGFloat?) {

		self.rootElementDefinition = rootElementDefinition
		self.bindings = bindings
		self.hasBindings = hasBindings
		self.ids = ids

		self.selectAction = selectAction
		self.layoutCacheKey = layoutCacheKey

		self.containerBackgroundColor = containerBackgroundColor
		self.containerCornerRadius = containerCornerRadius
	}


	public func createRootElement(forUi ui: Any) -> UiElement {
		let mirror = Mirror(reflecting: ui)
		var existingElementById = [String: UiElement]()
		for member in mirror.children {
			if let name = member.label {
				if ids.contains(name) {
					existingElementById[name] = member.value as? UiElement
				}
			}
		}

		let rootElement = createOrReuseElement(rootElementDefinition, existingElementById: existingElementById)

		return rootElement
	}



	private func createOrReuseElement(definition: UiElementDefinition, existingElementById: [String:UiElement]) -> UiElement {
		var children = [UiElement]()
		for childDefinition in definition.childrenDefinitions {
			children.append(createOrReuseElement(childDefinition, existingElementById: existingElementById))
		}
		let element: UiElement = (definition.id != nil ? existingElementById[definition.id!] : nil) ?? definition.createElement()
		definition.initialize(element, children: children)
		return element
	}



	public static func fromDeclaration(declaration: DeclarationElement, context: DeclarationContext) throws -> UiDefinition {
		var containerBackgroundColor: UIColor?
		var containerCornerRadius: CGFloat?
		var selectAction: UiBindings.Expression?
		var layoutCacheKey: UiBindings.Expression?

		for index in 1 ..< declaration.attributes.count {
			let attribute = declaration.attributes[index]
			switch attribute.name {
				case "background-color":
					containerBackgroundColor = try context.getColor(attribute)
				case "corner-radius":
					containerCornerRadius = try context.getFloat(attribute)
				case "select-action":
					selectAction = try context.getExpression(attribute)
				case "layout-cache-key":
					layoutCacheKey = try context.getExpression(attribute)
				default:
					break
			}
		}
		let rootElementDefinition = try UiElementDefinition.fromDeclaration(declaration.children[0], context: context)
		var ids = Set<String>()
		rootElementDefinition.traversal {
			if let id = $0.id {
				ids.insert(id)
			}
		}
		return UiDefinition(rootElementDefinition: rootElementDefinition,
			bindings: context.bindings,
			hasBindings: context.hasBindings,
			ids: ids,
			selectAction: selectAction,
			layoutCacheKey: layoutCacheKey,
			containerBackgroundColor: containerBackgroundColor,
			containerCornerRadius: containerCornerRadius)
	}
}
