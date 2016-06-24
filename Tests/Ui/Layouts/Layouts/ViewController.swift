//
//  ViewController.swift
//  Layouts
//
//  Created by Michael Vlasov on 15.06.16.
//  Copyright © 2016 Michael Vlasov. All rights reserved.
//

import UIKit
import Unified


public class Ui<Model>: RepositoryDependent, RepositoryListener {

	public var layoutCache: LayoutCache?

	public var container: UIView? {
		get {
			return currentContainer
		}
		set {
			if currentLayout != nil {
				setLayout(currentLayout!, container: newValue)
			}
			else {
				currentContainer = newValue
			}
		}
	}

	public var model: Model? {
		didSet {
			onModelChanged()
			performLayout()
		}
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
		if currentLayout == nil {
			setLayout(createLayout(currentLayoutName), container: currentContainer)
		}

		currentLayout!.measureMaxSize(bounds)
		currentLayout!.measureSize(bounds)
		frame = currentLayout!.layout(CGRectMake(0, 0, bounds.width, bounds.height))

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
		if currentLayout != nil {
			setLayout(createLayout(name), container: currentContainer)
		}
	}


	// MARK: - Virtuals


	public var layoutCacheKey: String {
		if let modelObject = model as? AnyObject {
			return String(ObjectIdentifier(modelObject).uintValue)
		}
		else {
			return ""
		}
	}

	public func onModelChanged() {
	}


	// MARK: - RepositoryListener


	public func repositoryChanged(repository: Repository) {
		setLayout(createLayout(currentLayoutName), container: currentContainer)
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
	private var currentLayout: LayoutItem?

	private var views = [LayoutViewItem]()
	private var frame = CGRectZero

	private func createLayout(name: String?) -> LayoutItem {
		let factory = try! repository.layoutFactory(forUi: self, name: name)
		return factory.createWith(self)
	}

	private func setLayout(layout: LayoutItem, container: UIView?) {
		let oldLayout = currentLayout
		let layoutChanged = !sameObjects(currentLayout, layout)
		let containerChanged = !sameObjects(currentContainer, container)

		guard layoutChanged || containerChanged else {
			return
		}

		if containerChanged && currentContainer != nil {
			for item in views {
				item.view?.removeFromSuperview()
			}
		}

		if layoutChanged {
			currentLayout = layout
			views.removeAll(keepCapacity: true)
			layout.traversal {
				if let item = $0 as? LayoutViewItem {
					views.append(item)
				}
			}
		}

		var hasNewViews = false
		currentContainer = container

		if containerChanged || oldLayout == nil {
			if container != nil {
				for item in views {
					if item.view == nil {
						item.view = item.createView()
						hasNewViews = true
					}
					container!.addSubview(item.view!)
				}
			}
		}

		if layoutChanged || hasNewViews {
			for item in views {
				if item.view != nil {
					item.initializeView()
				}
			}
		}

		if hasNewViews && model != nil {
			onModelChanged()
		}

		performLayout()
	}
}


struct TestModel {
	let text: String
	let details: String
	let warning: String
	let footer: String
}




class TestUi: Ui<TestModel> {
	let icon = LayoutView()
	let text = LayoutLabel()
	let details = LayoutLabel()
	let warning = LayoutLabel()
	let footer = LayoutLabel()

	override func onModelChanged() {
		text.text = model?.text
		details.text = model?.details
		warning.text = model?.warning
		footer.text = model?.footer
	}
}





class ViewController: UIViewController, Dependent {

	override func viewDidLoad() {
		super.viewDidLoad()

		createComponents()

		ui = TestUi()
		ui.dependency = dependency
		ui.container = view
		ui.model = createTestModel()
	}


	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		ui.performLayout()
	}


	var dependency: DependencyResolver!
	var ui: TestUi!


	private func createComponents() {
		let components = DependencyContainer()
		components.createDefaultRepository()
		components.required(RepositoryDependency).devServerUrl = NSURL(string: "ws://localhost:8080/events")
		dependency = components
	}

	private func createTestModel() -> TestModel {
		return TestModel(text: "Text",
			details: "Details Details Details Details Details Details Details Details Details Details Details Details Details Details Details Details Details",
			warning: "Warning",
			footer: "Footer")
	}

}

