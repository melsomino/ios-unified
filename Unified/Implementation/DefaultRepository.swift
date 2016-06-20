//
// Created by Власов М.Ю. on 20.06.16.
// Copyright (c) 2016 melsomino. All rights reserved.
//

import Foundation

public class DefaultRepository: Repository, Dependent {

	public func createLayoutFor(ui: AnyObject) throws -> LayoutItem {
		let uiClass: AnyClass = ui.dynamicType
		let uiClassName = String(NSStringFromClass(uiClass)).lowercaseString
		if let factory = layoutFactoryByClassName[uiClassName] {
			return factory.createWith(ui)
		}
		try loadRepositoriesInBundleForClass(uiClass)
		if let factory = layoutFactoryByClassName[uiClassName] {
			return factory.createWith(ui)
		}
		fatalError("UnifiedRepository does not contains layout definition for: \(uiClassName)")
	}

	public var devServerUrl: NSURL?

	public func addListener(listener: RepositoryListener) {
		listeners.add(listener)
	}

	public func removeListener(listener: RepositoryListener) {
		listeners.remove(listener)
	}


	public var dependency: DependencyResolver!


	// MARK: - Internals

	private var listeners = ListenerList<RepositoryListener>()
	private var loadedUniPaths = Set<String>()
	private var layoutFactoryByClassName = [String: LayoutItemFactory]()

	func loadRepositoriesInBundleForClass(forClass: AnyClass) throws {
		let bundle = NSBundle(forClass: forClass)
		for uniPath in bundle.pathsForResourcesOfType(".uni", inDirectory: nil) {
			guard !loadedUniPaths.contains(uniPath) else {
				continue
			}
			loadedUniPaths.insert(uniPath)
			let elements = try DeclarationElement.load(uniPath)
			for ui in elements.filter({ $0.name == "ui" }) {
				for layout in ui.children {
					let factory = try LayoutItemFactory.fromDeclaration(layout.children[0])
					layoutFactoryByClassName[layout.name] = factory
				}
			}
		}
	}
}



extension DependencyContainer {
	public func createDefaultRepository() {
		register(RepositoryDependency, DefaultRepository())
	}
}