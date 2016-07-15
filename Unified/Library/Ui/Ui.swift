//
// Created by Michael Vlasov on 27.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit


public class Ui: RepositoryDependent, RepositoryListener {

	public let modelType: Any.Type

	private var layoutName: String? {
		didSet {
			updateFactoryFromRepository()
		}
	}

	public var layoutCache: UiLayoutCache?

	public var container: UIView? {
		didSet {
			detachFromContainer()
			attachToContainer()
		}
	}

	public var backgroundColor: UIColor? {
		didSet {
			initializeContainer()
		}
	}

	public var cornerRadius: CGFloat? {
		didSet {
			initializeContainer()
		}
	}

	public var model: Any? {
		didSet {
			if factory == nil {
				updateFactoryFromRepository()
			}
			if modelValues.count > 0 {
				for i in 0 ..< modelValues.count {
					modelValues[i] = nil
				}
				if let model = model {
					let mirror = Mirror(reflecting: model)
					for member in mirror.children {
						if let name = member.label {
							if let index = factory!.bindings.valueIndexByName[name] {
								modelValues[index] = member.value
							}
						}
					}
				}
				rootElement?.traversal {
					$0.bindValues(modelValues)
				}
			}
			onModelChanged()
			performLayout()
		}
	}


	public init(forModelType modelType: Any.Type) {
		self.modelType = modelType
	}



	public func performLayout() {
		if let bounds = container?.bounds.size {
			performLayout(inBounds: bounds)
		}
	}

	public func performLayout(inWidth width: CGFloat) {
		if let cache = layoutCache {
			if let frames = cache.cachedFramesForWidth(width, key: layoutCacheKey) {
				frame = frames[0]
				for index in 0 ..< min(frames.count - 1, contentElements.count) {
					contentElements[index].frame = frames[index + 1]
				}
				return
			}
		}

		performLayout(inBounds: CGSizeMake(width, 10000))

		if let cache = layoutCache {
			var frames = [CGRect](count: 1 + contentElements.count, repeatedValue: CGRectZero)
			frames[0] = frame
			for index in 0 ..< contentElements.count {
				frames[index + 1] = contentElements[index].frame
			}
			cache.setFrames(frames, forWidth: width, key: layoutCacheKey)
		}
	}


	public func performLayout(inBounds bounds: CGSize) {
		if factory == nil {
			updateFactoryFromRepository()
		}
		rootElement!.measureMaxSize(bounds)
		rootElement!.measureSize(bounds)
		frame = rootElement!.layout(CGRectMake(0, 0, bounds.width, bounds.height))

		print("perform layout")
	}

	public private(set) var frame = CGRectZero

	// MARK: - Virtuals


	public func onModelChanged() {
	}


	public var layoutCacheKey: String {
		if let modelObject = model as? AnyObject {
			return String(ObjectIdentifier(modelObject).uintValue)
		}
		else {
			return ""
		}
	}


	// MARK: - RepositoryListener


	public func repositoryChanged(repository: Repository) {
		updateFactoryFromRepository()
	}


	// MARK: - Dependency


	public var dependency: DependencyResolver! {
		didSet {
			oldValue?.optional(RepositoryDependency)?.removeListener(self)
			optionalRepository?.addListener(self)
		}
	}


	// MARK: - Internals


	private var factory: UiFactory!
	private var rootElement: UiElement!
	private var contentElements = [UiContentElement]()
	private var modelValues = [Any?]()

	private func setFactory(factory: UiFactory?) {
		guard !sameObjects(factory, self.factory) else {
			return
		}

		self.factory = factory

		backgroundColor = factory?.backgroundColor
		cornerRadius = factory?.cornerRadius

		detachFromContainer()

		rootElement = factory?.rootFactory.createWith(self)
		contentElements.removeAll(keepCapacity: true)
		rootElement.traversal {
			dependency.resolve($0)
			if let element = $0 as? UiContentElement {
				contentElements.append(element)
			}
		}
		modelValues = [Any?](count: factory?.bindings.valueIndexByName.count ?? 0, repeatedValue: nil)

		attachToContainer()

		performLayout()
	}


	func updateFactoryFromRepository() {
		setFactory(try! repository.uiFactory(forModelType: modelType, name: layoutName))
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
		container?.backgroundColor = backgroundColor
		container?.layer.cornerRadius = cornerRadius ?? 0
		if cornerRadius != nil {
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




public class UiFactory {
	var backgroundColor: UIColor?
	var cornerRadius: CGFloat?

	private var rootFactory: UiElementFactory
	var bindings: UiBindings

	init(rootFactory: UiElementFactory, bindings: UiBindings) {
		self.rootFactory = rootFactory
		self.bindings = bindings
	}

	public static func fromDeclaration(element: DeclarationElement, context: DeclarationContext) throws -> UiFactory {
		let rootFactory = try UiElementFactory.fromDeclaration(element.children[0], context: context)
		let factory = UiFactory(rootFactory: rootFactory, bindings: context.bindings)
		for index in 1 ..< element.attributes.count {
			let attribute = element.attributes[index]
			switch attribute.name {
				case "background-color":
					factory.backgroundColor = try context.getColor(attribute)
				case "corner-radius":
					factory.cornerRadius = try context.getFloat(attribute)
				default:
					break
			}
		}
		return factory
	}
}
