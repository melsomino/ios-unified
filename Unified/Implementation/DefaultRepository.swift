// Created by Michael Vlasov on 20.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit
import Starscream

public class DefaultRepository: Repository, Dependent, WebSocketDelegate {

	public func uiFactory(forModelType modelType: Any.Type, name: String?) throws -> UiFactory {
		let uiName = makeUiName(forModelType: modelType, name: name)

		lock.lock()
		defer {
			lock.unlock()
		}

		if let factory = uiFactoryByName[uiName] {
			return factory
		}
		try loadRepositoriesInBundle(forType: modelType)
		if let factory = uiFactoryByName[uiName] {
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


	private func makeTypeName(forType type: Any.Type) -> String {
		return String(reflecting: type)
	}


	private func makeUiName(forModelType modelType: Any.Type, name: String?) -> String {
		let modelTypeName = makeTypeName(forType: modelType)
		return name != nil ? "\(modelTypeName).\(name!)" : modelTypeName
	}


	private func notify() {
		for listener in listeners.getLive() {
			listener.repositoryChanged(self)
		}
	}


	func loadRepositoriesInBundle(forType type: Any.Type) throws {
		let typeName = makeTypeName(forType: type)
		let typeNameParts = typeName.componentsSeparatedByString(".")
		let bundle = typeNameParts.count > 1 ? NSBundle.fromModuleName(typeNameParts[0])! : NSBundle(forClass: type as! AnyClass)

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