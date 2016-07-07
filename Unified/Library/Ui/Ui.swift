//
// Created by Michael Vlasov on 27.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit


public class Ui: RepositoryDependent, RepositoryListener {

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

	public var layoutCache: UiLayoutCache?

	public var container: UIView? {
		get {
			return currentContainer
		}
		set {
			if currentRoot != nil {
				setRoot(currentRoot!, container: newValue)
			}
			else {
				currentContainer = newValue
			}
			initializeContainer()
		}
	}

	public init() {
	}

	private func initializeContainer() {
		container?.backgroundColor = backgroundColor
		container?.layer.cornerRadius = cornerRadius ?? 0
		if cornerRadius != nil {
			container?.clipsToBounds = true
		}
	}

	public func createContainer(inWidth width: CGFloat) -> UIView {
		performLayout(inWidth: width)
		let container = UIView(frame: frame)
		return container
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
				for index in 0 ..< min(frames.count - 1, views.count) {
					views[index].frame = frames[index + 1]
				}
				return
			}
		}

		performLayout(inBounds: CGSizeMake(width, 10000))

		if let cache = layoutCache {
			var frames = [CGRect](count: 1 + views.count, repeatedValue: CGRectZero)
			frames[0] = frame
			for index in 0 ..< views.count {
				frames[index + 1] = views[index].frame
			}
			cache.setFrames(frames, forWidth: width, key: layoutCacheKey)
		}
	}


	public func performLayout(inBounds bounds: CGSize) {
		if currentRoot == nil {
			setRoot(createLayout(currentLayoutName), container: currentContainer)
		}

		currentRoot!.measureMaxSize(bounds)
		currentRoot!.measureSize(bounds)
		frame = currentRoot!.layout(CGRectMake(0, 0, bounds.width, bounds.height))

		print("perform layout")
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


	public func setLayoutName(name: String? = nil) {
		guard !same(name, currentLayoutName) else {
			return
		}
		currentLayoutName = name
		if currentRoot != nil {
			setRoot(createLayout(name), container: currentContainer)
		}
	}


	// MARK: - Virtuals


	public var layoutCacheKey: String {
		return String(ObjectIdentifier(self).uintValue)
	}


	// MARK: - RepositoryListener


	public func repositoryChanged(repository: Repository) {
		setRoot(createLayout(currentLayoutName), container: currentContainer)
	}



	// MARK: - Dependency


	public var dependency: DependencyResolver! {
		didSet {
			oldValue?.optional(RepositoryDependency)?.removeListener(self)
			optionalRepository?.addListener(self)
		}
	}


	// MARK: - Internals


	private var currentContainer: UIView?
	private var currentLayoutName: String?
	private var currentRoot: UiElement?

	private var views = [UiContentElement]()
	public private(set) var frame = CGRectZero

	private func createLayout(name: String?) -> UiElement {
		let factory = try! repository.uiFactory(forUi: self, name: name)
		backgroundColor = factory.backgroundColor
		cornerRadius = factory.cornerRadius
		return factory.rootFactory.createWith(self)
	}

	private func setRoot(root: UiElement, container: UIView?) {
		let oldRoot = currentRoot
		let rootChanged = !sameObjects(currentRoot, root)
		let containerChanged = !sameObjects(currentContainer, container)

		guard rootChanged || containerChanged else {
			return
		}

		if containerChanged && currentContainer != nil {
			for item in views {
				item.view?.removeFromSuperview()
			}
		}

		if rootChanged {
			currentRoot = root
			views.removeAll(keepCapacity: true)
			root.traversal {
				if let item = $0 as? UiContentElement {
					views.append(item)
				}
			}
		}

		var hasNewViews = false
		currentContainer = container

		if containerChanged || oldRoot == nil {
			if container != nil {
				for item in views {
					if item.view == nil {
						item.view = item.createView()
						item.onViewCreated()
						hasNewViews = true
					}
					container!.addSubview(item.view!)
				}
			}
		}

		if rootChanged || hasNewViews {
			for item in views {
				if item.view != nil {
					item.initializeView()
				}
			}
		}

		if hasNewViews {
			onSomeViewsCreated()
		}

		performLayout()
	}

	public func onSomeViewsCreated() {
	}
}



public class ModelUi<Model>: Ui {

	public var model: Model? {
		didSet {
			onModelChanged()
			performLayout()
		}
	}


	public override init() {
		super.init()
	}



	public override func onSomeViewsCreated() {
		if model != nil {
			onModelChanged()
		}
	}

	// MARK: - Virtuals


	public override var layoutCacheKey: String {
		if let modelObject = model as? AnyObject {
			return String(ObjectIdentifier(modelObject).uintValue)
		}
		else {
			return ""
		}
	}

	public func onModelChanged() {
	}
}



public class UiFactory {
	var backgroundColor: UIColor?
	var cornerRadius: CGFloat?

	var rootFactory: UiElementFactory

	init(root: UiElementFactory) {
		self.rootFactory = root
	}

	public static func fromDeclaration(element: DeclarationElement, context: DeclarationContext) throws -> UiFactory {
		let factory = UiFactory(root: try UiElementFactory.fromDeclaration(element.children[0], context: context))
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
