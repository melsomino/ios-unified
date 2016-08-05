//
// Created by Michael Vlasov on 27.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit


public protocol FragmentDelegate: class {
	func onAction(action: String, args: String?)
}


public class Fragment: RepositoryDependent, RepositoryListener {

	public final let modelType: Any.Type
	public final var layoutCacheKeyProvider: ((Any) -> String?)?
	public final var performLayoutInWidth = false
	public final var definition: FragmentDefinition! {
		return internalDefinition
	}
	public var layoutName: String? {
		didSet {
			updateDefinitionFromRepository()
		}
	}
	public weak var delegate: FragmentDelegate?
	public var layoutCache: FragmentLayoutCache?
	public var container: UIView? {
		didSet {
			internalDidSetContainer()
		}
	}
	public var model: Any? {
		didSet {
			internalDidSetModel()
		}
	}
	public private(set) var frame = CGRectZero


	public final func heightFor(model: Any, inWidth width: CGFloat) -> CGFloat {
		return internalHeightFor(model, inWidth: width)
	}

	public final func performLayout() {
		internalPerformLayout()
	}

	public final func performLayout(inWidth width: CGFloat) {
		internalPerformLayout(inWidth: width)
	}

	public final func performLayout(inBounds bounds: CGSize) {
		internalPerformLayout(inBounds: bounds)
	}

	public final func tryExecuteAction(action: DynamicBindings.Expression?) {
		internalTryExecuteAction(action)
	}

	public init(forModelType modelType: Any.Type) {
		self.modelType = modelType
	}


	// MARK: - Overridable


	public func onModelChanged() {
	}


	public func getLayoutCacheKey(forModel model: Any) -> String? {
		return defaultGetLayoutCacheKey(forModel: model)
	}


	// MARK: - RepositoryListener


	public func repositoryChanged(repository: Repository) {
		updateDefinitionFromRepository()
	}


	// MARK: - Dependency


	public var dependency: DependencyResolver! {
		willSet {
			optionalRepository?.removeListener(self)
		}
		didSet {
			optionalRepository?.addListener(self)
		}
	}


	// MARK: - Internals


	private var rootElement: FragmentElement!
	private var contentElements = [ContentElement]()
	private var modelValues = [Any?]()
	private var currentDefinition: FragmentDefinition?
	private func definitionRequired() {
		if currentDefinition == nil {
			updateDefinitionFromRepository()
		}
	}

	private var internalDefinition: FragmentDefinition! {
		definitionRequired()
		return currentDefinition
	}

	private func internalDidSetContainer() {
		detachFromContainer()
		attachToContainer()
	}


	private func heightWithMargin(frame: CGRect) -> CGFloat {
		let margin = rootElement!.margin
		return frame.height + margin.top + margin.bottom
	}

	private func internalHeightFor(model: Any, inWidth width: CGFloat) -> CGFloat {
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


	private func internalPerformLayout() {
		if let bounds = container?.bounds.size {
			if performLayoutInWidth {
				performLayout(inWidth: bounds.width)
			}
			else {
				performLayout(inBounds: bounds)
			}
		}
	}


	private func internalPerformLayout(inWidth width: CGFloat) {
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

		definitionRequired()
		let size = rootElement!.measure(inBounds: CGSizeMake(width, 0))
		frame = CGRectMake(0, 0, width, size.height)
		rootElement!.layout(inBounds: frame, usingMeasured: size)

		if layoutCacheKey != nil {
			var frames = [CGRect](count: 1 + contentElements.count, repeatedValue: CGRectZero)
			frames[0] = frame
			for index in 0 ..< contentElements.count {
				frames[index + 1] = contentElements[index].frame
			}
			layoutCache!.setFrames(frames, forWidth: width, key: layoutCacheKey!)
		}
	}


	private func internalPerformLayout(inBounds bounds: CGSize) {
		definitionRequired()
		frame = CGRect(origin: CGPointZero, size: bounds)
		let size = rootElement!.measure(inBounds: bounds)
		rootElement!.layout(inBounds: frame, usingMeasured: size)
	}



	private func internalTryExecuteAction(action: DynamicBindings.Expression?) {
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

	private func internalDidSetModel() {
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


	private func defaultGetLayoutCacheKey(forModel model: Any) -> String? {
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

	private func resolveLayoutCacheKey(forModel model: Any?) -> String? {
		guard let model = model else {
			return nil
		}
		return getLayoutCacheKey(forModel: model)
	}


	private func setDefinition(definition: FragmentDefinition?) {
		guard !sameObjects(definition, self.currentDefinition) else {
			return
		}

		self.currentDefinition = definition

		detachFromContainer()

		rootElement = definition?.createRootElement(forUi: self)
		contentElements.removeAll(keepCapacity: true)
		rootElement.traversal {
			dependency.resolve($0)
			if let element = $0 as? ContentElement {
				contentElements.append(element)
			}
		}
		modelValues = [Any?](count: definition?.bindings.valueIndexByName.count ?? 0, repeatedValue: nil)

		attachToContainer()

		internalDidSetModel()
	}


	func updateDefinitionFromRepository() {
		setDefinition(try! repository.uiDefinition(forModelType: modelType, name: layoutName))
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

}





public class FragmentDefinition {

	// MARK: - Public

	public final let bindings: DynamicBindings
	public final let hasBindings: Bool

	public final let selectAction: DynamicBindings.Expression?
	public final let layoutCacheKey: DynamicBindings.Expression?

	public final let containerBackgroundColor: UIColor?
	public final let containerCornerRadius: CGFloat?


	public final func createRootElement(forUi ui: Any) -> FragmentElement {
		return internalCreateRootElement(forUi: ui)
	}

	public static func fromDeclaration(declaration: DeclarationElement, context: DeclarationContext) throws -> FragmentDefinition {
		return try FragmentDefinition.internalFromDeclaration(declaration, context: context)
	}

	init(rootElementDefinition: FragmentElementDefinition,
		bindings: DynamicBindings,
		hasBindings: Bool,
		ids: Set<String>,
		selectAction: DynamicBindings.Expression?,
		layoutCacheKey: DynamicBindings.Expression?,
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


	// MARK: - Internals


	private let rootElementDefinition: FragmentElementDefinition
	private let ids: Set<String>


	private func internalCreateRootElement(forUi ui: Any) -> FragmentElement {
		let mirror = Mirror(reflecting: ui)
		var existingElementById = [String: FragmentElement]()
		for member in mirror.children {
			if let name = member.label {
				if ids.contains(name) {
					existingElementById[name] = member.value as? FragmentElement
				}
			}
		}

		let rootElement = createOrReuseElement(rootElementDefinition, existingElementById: existingElementById)

		return rootElement
	}


	private static func internalFromDeclaration(declaration: DeclarationElement, context: DeclarationContext) throws -> FragmentDefinition {
		var containerBackgroundColor: UIColor?
		var containerCornerRadius: CGFloat?
		var selectAction: DynamicBindings.Expression?
		var layoutCacheKey: DynamicBindings.Expression?

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
		let rootElementDefinition = try FragmentElementDefinition.from(declaration: declaration.children[0], context: context)
		var ids = Set<String>()
		rootElementDefinition.traversal {
			if let id = $0.id {
				ids.insert(id)
			}
		}
		return FragmentDefinition(rootElementDefinition: rootElementDefinition,
			bindings: context.bindings,
			hasBindings: context.hasBindings,
			ids: ids,
			selectAction: selectAction,
			layoutCacheKey: layoutCacheKey,
			containerBackgroundColor: containerBackgroundColor,
			containerCornerRadius: containerCornerRadius)
	}



	private func createOrReuseElement(definition: FragmentElementDefinition, existingElementById: [String:FragmentElement]) -> FragmentElement {
		var children = [FragmentElement]()
		for childDefinition in definition.childrenDefinitions {
			children.append(createOrReuseElement(childDefinition, existingElementById: existingElementById))
		}
		let element: FragmentElement = (definition.id != nil ? existingElementById[definition.id!] : nil) ?? definition.createElement()
		definition.initialize(element, children: children)
		return element
	}
}
