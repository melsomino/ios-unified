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



public class ActionRouting {
	public final let action: String
	public final let value: String

	public init(action: String, value: String) {
		self.action = action
		self.value = value
	}

	public init(combined: String?) {
		(action, value) = ActionRouting.parse(combined: combined)
	}

	convenience public init(expression: DynamicBindings.Expression?, values: [Any?]) {
		self.init(combined: expression?.evaluate(values))
	}



	public static func parse(combined: String?) -> (action: String, value: String) {
		if let combined = combined, let separator = combined.rangeOfCharacter(from: CharacterSet.whitespaces) {
			return (combined.substring(to: separator.lowerBound),
				combined.substring(from: separator.upperBound).trimmingCharacters(in: CharacterSet.whitespaces))
		}
		else {
			return (combined ?? "", "")
		}
	}
}



public protocol FragmentDelegate: class {
	var controller: UIViewController! { get }
	func onAction(routing: ActionRouting)



	func layoutChanged(forFragment fragment: Fragment)
}



open class Fragment: NSObject, RepositoryDependent, RepositoryListener, FragmentDelegate {

	public final let modelType: AnyObject.Type
	public final var performLayoutInWidth = false
	public final var definition: FragmentDefinition! {
		get {
			return internalDefinition
		}
		set {
			setDefinition(newValue)
		}
	}
	open var layoutName: String? {
		didSet {
			updateDefinitionFromRepository()
		}
	}
	open weak var delegate: FragmentDelegate?
	open var layoutCache: FragmentLayoutCache?

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

	public final var layoutCacheKey: String? {
		return model != nil ? getLayoutCacheKey(forModel: model!) : nil
	}


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



	public init(forModelType modelType: AnyObject.Type) {
		self.modelType = modelType
	}


	public convenience init(definition: FragmentDefinition, dependency: DependencyResolver) {
		self.init(forModelType: AnyObject.self)
		dependency.resolve(self)
		self.definition = definition
	}



	public final func reflectCellHighlight(_ highlight: Bool) {
		internalUpdateBackgroundSensitiveElements(toBackgroundColor: highlight ? UIColor.parse("dadada") : UIColor.white)
	}



	open func notifyLayoutChanged() {
		delegate?.layoutChanged(forFragment: self)
	}


	// MARK: - FragmentDelegate


	open var controller: UIViewController! {
		return delegate?.controller
	}


	open func layoutChanged(forFragment fragment: Fragment) {
		delegate?.layoutChanged(forFragment: fragment)
	}



	open func onAction(routing: ActionRouting) {
		delegate?.onAction(routing: routing)
	}



	// MARK: - Overridable


	open func onBeforePerformLayoutInBounds(inBounds bounds: CGSize) {
	}



	open func onPerformLayoutCompleteAfterModelChange() {

	}



	open func onModelChanged() {
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
	public private(set) final var modelValues = [Any?]()
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
		if let cache = layoutCache, let layoutCacheKey = getLayoutCacheKey(forModel: model) {
			if let frames = cache.frames(forWidth: width, fragment: layoutCacheKey) {
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
			if let frames = layoutCache!.frames(forWidth: width, fragment: layoutCacheKey!) {
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
			layoutCache!.set(frames: frames, forWidth: width, fragment: layoutCacheKey!)
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



	private func internalDidSetModel() {
		definitionRequired()
		guard let definition = currentDefinition else {
			return
		}
		if modelValues.count > 0 {
			for i in 0 ..< modelValues.count {
				modelValues[i] = nil
			}
			if let model = model {
				definition.bindings.fill(model: model, values: &modelValues)
			}
		}
		if definition.hasBindings {
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
		guard let definition = currentDefinition, let keyBinding = definition.layoutCacheKey else {
			return nil
		}
		var values = [Any?](repeating: nil, count: definition.bindings.valueIndexByName.count)
		definition.bindings.fill(model: model, values: &values)
		return keyBinding.evaluate(values)
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
		guard modelType != AnyObject.self else {
			return
		}
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

	public final let selectAction: FragmentAction?
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
		selectAction: FragmentAction?,
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
		let selectAction = try FragmentAction.from(element: element, context: context, name: "select-action")
		var selectionStyle = UITableViewCellSelectionStyle.default
		var layoutCacheKey: DynamicBindings.Expression?

		for attribute in element.attributes(from: startAttribute + 1) {
			switch attribute.name {
				case "background-color":
					containerBackgroundColor = try context.getColor(attribute)
				case "corner-radius":
					containerCornerRadius = try context.getFloat(attribute)
				case "selection-style":
					selectionStyle = try context.getEnum(attribute, selectionStyleByName)
				case "layout-cache-key":
					layoutCacheKey = try context.getExpression(attribute)
				default:
					break
			}
		}
		let children = DeclarationTemplate.apply(templates: context.templates, to: element.children)
		guard let rootElementDeclaration = children.first else {
			throw DeclarationError("Fragment declaration does not contains root element declaration", element, context)
		}
		let rootElementDefinition = try FragmentElementDefinition.from(declaration: rootElementDeclaration, context: context)
		var ids = Set<String>()
		var layoutIndex = 1
		rootElementDefinition.traversal {
			if let id = $0.id {
				ids.insert(id)
			}
			$0.layoutIndex = layoutIndex
			layoutIndex += 1
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



	private func createOrReuseElement(_ fragment: Fragment, definition: FragmentElementDefinition, existingElementById: [String: FragmentElement]) -> FragmentElement {
		var children = [FragmentElement]()
		for childDefinition in definition.childrenDefinitions {
			children.append(createOrReuseElement(fragment, definition: childDefinition, existingElementById: existingElementById))
		}
		let element: FragmentElement = (definition.id != nil ? existingElementById[definition.id!] : nil) ?? definition.createElement()
		element.fragment = fragment
		definition.initialize(element, children: children)
		return element
	}

	static let selectionStyleByName: [String: UITableViewCellSelectionStyle] = [
		"none": .none,
		"blue": .blue,
		"gray": .gray,
		"default": .default
	]

	static let RepositorySection = "fragment"
	static func createFromRepository(_ element: DeclarationElement, _ startAttribute: Int, _ context: DeclarationContext) throws -> (String, AnyObject) {
		let name = element.attributes[startAttribute].name
		let definition = try FragmentDefinition.from(element: element, startAttribute: startAttribute, context: context)
		return (name, definition)
	}



	static func setup() {
		DefaultRepository.register(section: RepositorySection + " ui", itemFactory: createFromRepository)
	}
}



public class FragmentContainer: UIView {
	public var fragment: Fragment!

	public override func layoutSubviews() {
		super.layoutSubviews()
		guard let fragment = fragment else {
			return
		}
		if fragment.performLayoutInWidth {
			fragment.performLayout(inWidth: bounds.width)
		}
		else {
			fragment.performLayout(inBounds: bounds.size)
		}
	}

}



extension Repository {
	public func fragmentDefinition(for modelType: AnyObject.Type, name: String?) throws -> FragmentDefinition {
		if let definition = try findDefinition(for: modelType, with: name, in: FragmentDefinition.RepositorySection) as? FragmentDefinition {
			return definition
		}
		fatalError("Repository does not contains fragment definition: \(String(reflecting: modelType))")
	}

}