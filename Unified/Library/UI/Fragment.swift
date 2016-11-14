//
// Created by Michael Vlasov on 27.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

class UnifiedUi {
	public static func setup() {
		FragmentDefinition.setup()
		FrameDefinition.setup()
	}
}

public protocol FragmentDelegate: class {
	var controller: UIViewController! { get }
	func onAction(_ action: String, args: String?)
	func layoutChanged(forFragment fragment: Fragment)
}


open class Fragment: NSObject, RepositoryDependent, RepositoryListener, FragmentElementDelegate {


	public final let modelType: AnyObject.Type
	public final var layoutCacheKeyProvider: ((AnyObject) -> String?)?
	public final var performLayoutInWidth = false
	public final var definition: FragmentDefinition! {
		return internalDefinition
	}
	open var layoutName: String? {
		didSet {
			updateDefinitionFromRepository()
		}
	}
	open weak var delegate: FragmentDelegate?
	open var layoutCache: FragmentLayoutCache?
	open var controller: UIViewController! {
		return delegate?.controller
	}

	open var container: UIView? {
		didSet {
			internalDidSetContainer()
		}
	}

	open var model: AnyObject? {
		didSet {
			internalDidSetModel()
		}
	}

	open private(set) var frame = CGRect.zero


	public final func heightFor(_ model: AnyObject, inWidth width: CGFloat) -> CGFloat {
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



	public final func tryExecuteAction(_ action: DynamicBindings.Expression?, defaultArgs: String?) {
		internalTryExecuteAction(action, defaultArgs: defaultArgs)
	}



	public init(forModelType modelType: AnyObject.Type) {
		self.modelType = modelType
	}



	public final func reflectCellHighlight(_ highlight: Bool) {
		internalUpdateBackgroundSensitiveElements(toBackgroundColor: highlight ? UIColor.parse("dadada") : UIColor.white)
	}

	open func notifyLayoutChanged() {
		delegate?.layoutChanged(forFragment: self)
	}

	// MARK: - Overridable


	open func onBeforePerformLayoutInBounds(inBounds bounds: CGSize) {
	}



	open func onPerformLayoutCompleteAfterModelChange() {

	}



	open func onModelChanged() {
	}



	open func onAction(_ action: String, args: String?) {
		delegate?.onAction(action, args: args)
	}



	open func getLayoutCacheKey(forModel model: AnyObject) -> String? {
		return defaultGetLayoutCacheKey(forModel: model)
	}

	// MARK: - Element Delegate

	open func layoutChanged(forElement element: FragmentElement) {
		notifyLayoutChanged()
	}

	// MARK: - RepositoryListener


	open func repositoryChanged(_ repository: Repository) {
		updateDefinitionFromRepository()
	}


	// MARK: - Dependency


	open var dependency: DependencyResolver! {
		willSet {
			optionalRepository?.removeListener(self)
		}
		didSet {
			optionalRepository?.addListener(self)
		}
	}


	// MARK: - Internals


	open private(set) var rootElement: FragmentElement!
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



	private func heightWithMargin(_ frame: CGRect) -> CGFloat {
		let margin = rootElement!.margin
		return frame.height + margin.top + margin.bottom
	}



	private func internalHeightFor(_ model: AnyObject, inWidth width: CGFloat) -> CGFloat {
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
				if rootElement != nil {
					checkVisibilityOfContentElements(rootElement, parentHidden: false)
				}
				return
			}
		}

		definitionRequired()
		onBeforePerformLayoutInBounds(inBounds: CGSize(width: width, height: 0))
		let measure = rootElement!.measure(inBounds: CGSize(width: width, height: 0))
		frame = CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: measure.height))
		rootElement!.layout(inBounds: frame, usingMeasured: measure.maxSize)
		if rootElement != nil {
			checkVisibilityOfContentElements(rootElement, parentHidden: false)
		}

		if layoutCacheKey != nil {
			var frames = [CGRect](repeating: CGRect.zero, count: 1 + contentElements.count)
			frames[0] = frame
			for index in 0 ..< contentElements.count {
				frames[index + 1] = contentElements[index].frame
			}
			layoutCache!.setFrames(frames, forWidth: width, key: layoutCacheKey!)
		}
	}



	private func internalPerformLayout(inBounds bounds: CGSize) {
		definitionRequired()
		onBeforePerformLayoutInBounds(inBounds: bounds)
		let measure = rootElement!.measure(inBounds: bounds)
		frame = CGRect(origin: CGPoint.zero, size: bounds)
		rootElement!.layout(inBounds: frame, usingMeasured: measure.maxSize)
		if rootElement != nil {
			checkVisibilityOfContentElements(rootElement, parentHidden: false)
		}
	}



	private func checkVisibilityOfContentElements(_ parent: FragmentElement!, parentHidden: Bool) {
		if parent == nil {
			return
		}
		if let content = parent as? ContentElement {
			if let view = content.view {
				view.isHidden = parentHidden || !content.visible
			}
			if let decorator = parent as? DecoratorElement {
				checkVisibilityOfContentElements(decorator.child, parentHidden: parentHidden || decorator.hidden)
			}
		}
		else if let multipleContainer = parent as? MultipleElementContainer {
			for child in multipleContainer.children {
				checkVisibilityOfContentElements(child, parentHidden: parentHidden || multipleContainer.hidden)
			}
		}
		else if let singleContainer = parent as? SingleElementContainer {
			checkVisibilityOfContentElements(singleContainer.child, parentHidden: parentHidden)
		}
	}



	private func internalTryExecuteAction(_ action: DynamicBindings.Expression?, defaultArgs: String?) {
		guard let actionWithArgs = action?.evaluate(modelValues) else {
			return
		}
		var name: String
		var args: String?
		if let argsSeparator = actionWithArgs.rangeOfCharacter(from: CharacterSet.whitespaces) {
			name = actionWithArgs.substring(to: argsSeparator.lowerBound)
			args = actionWithArgs.substring(from: argsSeparator.upperBound).trimmingCharacters(in: CharacterSet.whitespaces)
			if args!.isEmpty {
				args = defaultArgs
			}
		}
		else {
			name = actionWithArgs
			args = defaultArgs
		}
		onAction(name, args: args)
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
		onPerformLayoutCompleteAfterModelChange()
	}



	private func internalUpdateBackgroundSensitiveElements(toBackgroundColor color: UIColor) {
		rootElement.traversal {
			element in
			guard let decorator = element as? DecoratorElement else {
				return
			}
			decorator.reflectParentBackgroundTo(color)
		}
	}



	private func defaultGetLayoutCacheKey(forModel model: AnyObject) -> String? {
		definitionRequired()
		guard let keyProvider = currentDefinition!.layoutCacheKey, let definition = currentDefinition else {
			return nil
		}
		var values = [Any?](repeating: nil, count: definition.bindings.valueIndexByName.count)
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



	private func resolveLayoutCacheKey(forModel model: AnyObject?) -> String? {
		guard let model = model else {
			return nil
		}
		return getLayoutCacheKey(forModel: model)
	}



	private func setDefinition(_ definition: FragmentDefinition?) {
		guard !sameObjects(definition, self.currentDefinition) else {
			return
		}

		self.currentDefinition = definition

		detachFromContainer()

		rootElement = definition?.createRootElement(forFragment: self)
		contentElements.removeAll(keepingCapacity: true)
		rootElement.traversal {
			dependency.resolve($0)
			if let element = $0 as? ContentElement {
				contentElements.append(element)
			}
		}
		modelValues = [Any?](repeating: nil, count: definition?.bindings.valueIndexByName.count ?? 0)

		attachToContainer()

		internalDidSetModel()
	}



	func updateDefinitionFromRepository() {
		setDefinition(try! repository.fragmentDefinition(forModelType: modelType, name: layoutName))
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





open class FragmentDefinition {

	// MARK: - Public

	public final let bindings: DynamicBindings
	public final let hasBindings: Bool

	public final let selectAction: DynamicBindings.Expression?
	public final let selectionStyle: UITableViewCellSelectionStyle
	public final let layoutCacheKey: DynamicBindings.Expression?

	public final let containerBackgroundColor: UIColor?
	public final let containerCornerRadius: CGFloat?


	public final func createRootElement(forFragment fragment: Fragment) -> FragmentElement {
		return internalCreateRootElement(forFragment: fragment)
	}



	init(rootElementDefinition: FragmentElementDefinition,
		bindings: DynamicBindings,
		hasBindings: Bool,
		ids: Set<String>,
		selectAction: DynamicBindings.Expression?,
		selectionStyle: UITableViewCellSelectionStyle,
		layoutCacheKey: DynamicBindings.Expression?,
		containerBackgroundColor: UIColor?,
		containerCornerRadius: CGFloat?) {

		self.rootElementDefinition = rootElementDefinition
		self.bindings = bindings
		self.hasBindings = hasBindings
		self.ids = ids

		self.selectAction = selectAction
		self.selectionStyle = selectionStyle
		self.layoutCacheKey = layoutCacheKey

		self.containerBackgroundColor = containerBackgroundColor
		self.containerCornerRadius = containerCornerRadius
	}


	// MARK: - Internals


	private let rootElementDefinition: FragmentElementDefinition
	private let ids: Set<String>


	private func internalCreateRootElement(forFragment fragment: Fragment) -> FragmentElement {
		let mirror = Mirror(reflecting: fragment)
		var existingElementById = [String: FragmentElement]()
		for member in mirror.children {
			if let name = member.label {
				if ids.contains(name) {
					existingElementById[name] = member.value as? FragmentElement
				}
			}
		}

		let rootElement = createOrReuseElement(fragment, definition: rootElementDefinition, existingElementById: existingElementById)


		return rootElement
	}



	public static func from(element: DeclarationElement, startAttribute: Int, context: DeclarationContext) throws -> FragmentDefinition {
		var containerBackgroundColor: UIColor?
		var containerCornerRadius: CGFloat?
		var selectAction: DynamicBindings.Expression?
		var selectionStyle = UITableViewCellSelectionStyle.default
		var layoutCacheKey: DynamicBindings.Expression?

		for index in startAttribute + 1 ..< element.attributes.count {
			let attribute = element.attributes[index]
			switch attribute.name {
				case "background-color":
					containerBackgroundColor = try context.getColor(attribute)
				case "corner-radius":
					containerCornerRadius = try context.getFloat(attribute)
				case "select-action":
					selectAction = try context.getExpression(attribute)
				case "selection-style":
					selectionStyle = try context.getEnum(attribute, selectionStyleByName)
				case "layout-cache-key":
					layoutCacheKey = try context.getExpression(attribute)
				default:
					break
			}
		}
		let rootElementDefinition = try FragmentElementDefinition.from(declaration: element.children[0], context: context)
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
			selectionStyle: selectionStyle,
			layoutCacheKey: layoutCacheKey,
			containerBackgroundColor: containerBackgroundColor,
			containerCornerRadius: containerCornerRadius)
	}



	private func createOrReuseElement(_ fragment: Fragment, definition: FragmentElementDefinition, existingElementById: [String:FragmentElement]) -> FragmentElement {
		var children = [FragmentElement]()
		for childDefinition in definition.childrenDefinitions {
			children.append(createOrReuseElement(fragment, definition: childDefinition, existingElementById: existingElementById))
		}
		let element: FragmentElement = (definition.id != nil ? existingElementById[definition.id!] : nil) ?? definition.createElement()
		element.delegate = fragment
		definition.initialize(element, children: children)
		return element
	}

	static let selectionStyleByName: [String:UITableViewCellSelectionStyle] = [
		"none": .none,
		"blue": .blue,
		"gray": .gray,
		"default": .default
	]

	static let RepositorySection = "ui"
	static func setup() {
		DefaultRepository.register(section: RepositorySection) {
			element, startAttribute, context in
			return (element.attributes[startAttribute].name, try FragmentDefinition.from(element: element, startAttribute: startAttribute, context: context))
		}
	}
}
