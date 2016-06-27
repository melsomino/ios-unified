//
// Created by Michael Vlasov on 20.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit
import Starscream

public class DefaultRepository: Repository, Dependent, WebSocketDelegate {

	public func layoutFactory(forUi ui: AnyObject, name: String?) throws -> LayoutItemFactory {
		let uiClass: AnyClass = ui.dynamicType
		let layoutName = makeLayoutName(forClass: uiClass, name: name)
		let key = layoutName.lowercaseString

		lock.lock()
		defer {
			lock.unlock()
		}

		if let factory = layoutFactoryByName[key] {
			return factory
		}
		try loadRepositoriesInBundleForClass(uiClass)
		if let factory = layoutFactoryByName[key] {
			return factory
		}
		fatalError("Repository does not contains ui definition: \(layoutName)")
	}



	public var devServerUrl: NSURL? {
		didSet {
			devServerWebSocket?.disconnect()
			devServerWebSocket = nil
			if let url = devServerUrl {
				devServerWebSocket = WebSocket(url: url)
				devServerWebSocket!.delegate = self
				devServerWebSocket!.connect()
			}
		}
	}

	public func addListener(listener: RepositoryListener) {
		listeners.add(listener)
	}

	public func removeListener(listener: RepositoryListener) {
		listeners.remove(listener)
	}


	public var dependency: DependencyResolver!


	// MARK: - DevServer WebSocket Delegate


	public func websocketDidReceiveMessage(socket: WebSocket, text: String) {
		let parts = text.componentsSeparatedByString("`")
		switch parts[0] {
			case "repository-changed":
				socket.writeString("get-repository`\(parts[1])")
			case "repository":
				lock.lock()
				defer {
					lock.unlock()
				}
				try! loadRepository(DeclarationElement.parse(parts[1]), overrideExisting: true)
				notify()
			default:
				break
		}
	}


	public func websocketDidConnect(socket: WebSocket) {
		let device = UIDevice.currentDevice()
		socket.writeString("client-info`\(device.name), iOS \(device.systemVersion)")
	}


	public func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
		print("dev server disconnected")
	}


	public func websocketDidReceiveData(socket: WebSocket, data: NSData) {
	}


	// MARK: - Internals

	private var devServerWebSocket: WebSocket?

	private var listeners = ListenerList<RepositoryListener>()
	private var loadedUniPaths = Set<String>()
	private var layoutFactoryByName = [String: LayoutItemFactory]()
	private var lock = FastLock()


	private func makeLayoutName(forClass uiClass: AnyClass, name: String?) -> String {
		let uiClassName = String(NSStringFromClass(uiClass))
		return name != nil ? "\(uiClassName).\(name!)" : uiClassName
	}


	private func notify() {
		for listener in listeners.getLive() {
			listener.repositoryChanged(self)
		}
	}

	func loadRepositoriesInBundleForClass(forClass: AnyClass) throws {
		let bundle = NSBundle(forClass: forClass)
		for uniPath in bundle.pathsForResourcesOfType(".uni", inDirectory: nil) {
			guard !loadedUniPaths.contains(uniPath) else {
				continue
			}
			loadedUniPaths.insert(uniPath)
			try loadRepository(DeclarationElement.load(uniPath), overrideExisting: false)
		}
	}

	func loadRepository(elements: [DeclarationElement], overrideExisting: Bool) throws {
		let context = DeclarationContext(elements)
		for ui in elements.filter({ $0.name == "ui" }) {
			for layout in ui.children {
				if overrideExisting || layoutFactoryByName[layout.name] == nil {
					let factory = try LayoutItemFactory.fromDeclaration(layout.children[0], context: context)
					layoutFactoryByName[layout.name] = factory
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