// Created by Michael Vlasov on 20.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit
import Starscream





open class DefaultRepository: Repository, Dependent, WebSocketDelegate, CentralUIDependent {


	// MARK: - Repository

	open func load(repository name: String) throws -> [DeclarationElement] {
		return try load(repository: name, from: Bundle.main)
	}

	open func load(repository name: String, forType type: Any.Type) throws -> [DeclarationElement] {
		lock.lock()
		defer {
			lock.unlock()
		}
		return try load(repository: name, from: bundle(forType: type))
	}

	open func load(declarations name: String, fromModuleWithType type: Any.Type) throws -> [DeclarationElement] {
		lock.lock()
		defer {
			lock.unlock()
		}
		let repositoryBundle = bundle(forType: type)
		var declarations = [DeclarationElement]()
		for uniPath in repositoryBundle.paths(forResourcesOfType: ".uni", inDirectory: nil) {
			let elements = try DeclarationElement.load(uniPath)
			for declaration in elements.filter({ $0.name == name }) {
				declarations.append(declaration)
			}
		}
		return declarations
	}


	open func fragmentDefinition(forModelType modelType: Any.Type, name: String?) throws -> FragmentDefinition {
		lock.lock()
		defer {
			lock.unlock()
		}

		let fragmentName = makeFragmentName(forModelType: modelType, name: name)
		if let factory = fragmentDefinitionByName[fragmentName] {
			return factory
		}
		try loadRepositoriesInBundle(forType: modelType)
		if let factory = fragmentDefinitionByName[fragmentName] {
			return factory
		}
		fatalError("Repository does not contains fragment definition: \(fragmentName)")
	}


	open var devServerUrl: URL? {
		didSet {
			devServerConnection?.disconnect()
			devServerConnection = nil
			if let url = devServerUrl {
				devServerConnection = WebSocket(url: url)
				devServerConnection!.delegate = self
				devServerConnection!.connect()
			}
		}
	}

	open func addListener(_ listener: RepositoryListener) {
		listeners.add(listener)
	}


	open func removeListener(_ listener: RepositoryListener) {
		listeners.remove(listener)
	}


	open var dependency: DependencyResolver!


	// MARK: - DevServer WebSocket Delegate


	open func websocketDidReceiveMessage(socket: WebSocket, text: String) {
		let parts = text.components(separatedBy: "`")
		switch parts[0] {
			case "repository-changed":
				socket.write(string: "get-repository`\(parts[1])")
			case "repository":
				do {
					try loadRepositoryFromDevServer(parts[0], repositoryString: parts[1])
					notify()
				}
					catch let error {
					optionalCentralUI?.pushAlert(.error, message: String(describing: error))
					print(error)
				}
			default:
				break
		}
	}


	open func websocketDidConnect(socket: WebSocket) {
		let device = UIDevice.current
		socket.write(string: "client-info`\(device.name), iOS \(device.systemVersion)")
		print("dev server connected")
	}


	open func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
		print("dev server disconnected, trying to reconnet after 1 second...")
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(NSEC_PER_MSEC * 1000)) / Double(NSEC_PER_SEC)) {
			[weak self] in
			self?.devServerConnection?.connect()
		}
	}


	open func websocketDidReceiveData(socket: WebSocket, data: Data) {
	}


	// MARK: - Internals


	private var devServerConnection: WebSocket?

	private var listeners = ListenerList<RepositoryListener>()
	private var loadedUniPaths = Set<String>()
	private var fragmentDefinitionByName = [String: FragmentDefinition]()
	private var lock = NSRecursiveLock()


	private func makeTypeName(forType type: Any.Type) -> String {
		return String(reflecting: type)
	}


	private func makeFragmentName(forModelType modelType: Any.Type, name: String?) -> String {
		let modelTypeName = makeTypeName(forType: modelType)
		return name != nil ? "\(modelTypeName).\(name!)" : modelTypeName
	}


	private func notify() {
		for listener in listeners.getLive() {
			listener.repositoryChanged(self)
		}
	}


	private func loadRepositoryFromDevServer(_ repositoryName: String, repositoryString: String) throws {
		lock.lock()
		defer {
			lock.unlock()
		}
		var elements: [DeclarationElement]
		let context = DeclarationContext(repositoryName)
		do {
			elements = try DeclarationElement.parse(repositoryString)
		}
			catch let error as ParseError {
			throw DeclarationError(error, context)
		}
		try loadRepository(elements, context: context, overrideExisting: true)
	}


	private func loadRepositoriesInBundle(forType type: Any.Type) throws {
		let typeName = makeTypeName(forType: type)
		let typeNameParts = typeName.components(separatedBy: ".")
		let bundle = typeNameParts.count > 1 ? Bundle.requiredFromModuleName(typeNameParts[0]) : Bundle(for: type as! AnyClass)

		for uniPath in bundle.paths(forResourcesOfType: ".uni", inDirectory: nil) {
			guard !loadedUniPaths.contains(uniPath) else {
				continue
			}
			loadedUniPaths.insert(uniPath)
			var elements: [DeclarationElement]
			let context = DeclarationContext((uniPath as NSString).lastPathComponent)
			do {
				elements = try DeclarationElement.load(uniPath)
			}
				catch let error as ParseError {
				throw DeclarationError(error, context)
			}
			try loadRepository(elements, context: context, overrideExisting: false)
		}
	}


	private func loadRepository(_ elements: [DeclarationElement], context: DeclarationContext, overrideExisting: Bool) throws {
		for fragmentsSection in elements.filter({ $0.name == "ui" || $0.name == "fragment" }) {
			for fragment in fragmentsSection.children {
				if overrideExisting || fragmentDefinitionByName[fragment.name] == nil {
					context.reset()
					let fragmentDefinition = try FragmentDefinition.fromDeclaration(fragment, context: context)
					fragmentDefinitionByName[fragment.name] = fragmentDefinition
				}
			}
		}

	}



	private func bundle(forType type: Any.Type) -> Bundle {
		let typeName = makeTypeName(forType: type)
		let typeNameParts = typeName.components(separatedBy: ".")
		return typeNameParts.count > 1 ? Bundle.requiredFromModuleName(typeNameParts[0]) : Bundle(for: type as! AnyClass)
	}




	private func load(repository name: String, from bundle: Bundle) throws -> [DeclarationElement] {
		let context = DeclarationContext("[\(name).uni] in bundle [\(bundle.bundleIdentifier ?? "")]")
		guard let path = bundle.path(forResource: name, ofType: ".uni") else {
			throw DeclarationError("Unable to locate unified repository", context)
		}
		do {
			return try DeclarationElement.load(path)
		}
			catch let error as ParseError {
			throw DeclarationError(error, context)
		}
	}



}





extension DependencyContainer {
	public func createDefaultRepository() {
		register(RepositoryDependency, DefaultRepository())
	}
}
