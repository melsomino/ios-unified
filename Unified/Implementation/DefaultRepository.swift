// Created by Michael Vlasov on 20.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit
import Starscream

public class DefaultRepository: Repository, Dependent, WebSocketDelegate {

	public func uiFactory(forUi ui: AnyObject, name: String?) throws -> UiFactory {
		let uiClass: AnyClass = ui.dynamicType
		let uiName = makeUiName(forClass: uiClass, name: name)
		let key = uiName.lowercaseString

		lock.lock()
		defer {
			lock.unlock()
		}

		if let factory = uiFactoryByName[key] {
			return factory
		}
		try loadRepositoriesInBundleForClass(uiClass)
		if let factory = uiFactoryByName[key] {
			return factory
		}
		fatalError("Repository does not contains ui definition: \(uiName)")
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
				try! loadRepositoryFromDevServer(parts[1])
				notify()
			default:
				break
		}
	}

	private func loadRepositoryFromDevServer(repositoryString: String) throws {
		lock.lock()
		defer {
			lock.unlock()
		}
		try loadRepository(DeclarationElement.parse(repositoryString), overrideExisting: true)
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
	private var uiFactoryByName = [String: UiFactory]()
	private var lock = FastLock()


	private func makeUiName(forClass uiClass: AnyClass, name: String?) -> String {
		let uiClassName = String(NSStringFromClass(uiClass))
		return name != nil ? "\(uiClassName).\(name!)" : uiClassName
	}


	private func notify() {
		for listener in listeners.getLive() {
			listener.repositoryChanged(self)
		}
	}

	func loadRepositoriesInBundleForClass(forClass: AnyClass) throws {
		let classNameParts = String(NSStringFromClass(forClass)).componentsSeparatedByString(".")
		let bundle = classNameParts.count > 1 ? NSBundle.fromModuleName(classNameParts[0])! : NSBundle(forClass: forClass)

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
		for uiSection in elements.filter({ $0.name == "ui" }) {
			for ui in uiSection.children {
				if overrideExisting || uiFactoryByName[ui.name] == nil {
					let factory = try UiFactory.fromDeclaration(ui, context: context)
					uiFactoryByName[ui.name] = factory
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