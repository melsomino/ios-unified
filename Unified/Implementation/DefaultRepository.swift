// Created by Michael Vlasov on 20.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit
import Starscream



class RepositorySection {
	let itemFactory: (DeclarationElement, Int, DeclarationContext) throws -> (String, AnyObject)
	var itemByName = [String: AnyObject]()
	init(itemFactory: @escaping (DeclarationElement, Int, DeclarationContext) throws -> (String, AnyObject)) {
		self.itemFactory = itemFactory
	}
}



open class DefaultRepository: Repository, Dependent, WebSocketDelegate, CentralUIDependent {

	init() {
		for (sectionName, itemFactory) in DefaultRepository.itemFactoryBySectionName {
			register(section: sectionName, itemFactory: itemFactory)
		}
	}

	// MARK: - Repository

	open func load(repository name: String) throws -> [DeclarationElement] {
		return try load(repository: name, from: Bundle.main)
	}



	open func load(repository name: String, forType type: AnyObject.Type) throws -> [DeclarationElement] {
		lock.lock()
		defer {
			lock.unlock()
		}
		return try load(repository: name, from: bundle(forType: type))
	}



	open func load(declarations name: String, fromModuleWithType type: AnyObject.Type) throws -> [DeclarationElement] {
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



	open func fragmentDefinition(forModelType modelType: AnyObject.Type, name: String?) throws -> FragmentDefinition {
		if let definition = try findDefinition(for: modelType, with: name, in: FragmentDefinition.RepositorySection) as? FragmentDefinition {
			return definition
		}
		var definitionName = String(reflecting: modelType)
		if let name = name {
			definitionName += ".\(name)"
		}
		fatalError("Repository does not contains fragment definition: \(definitionName)")
	}

	open func register(section: String, itemFactory: @escaping (DeclarationElement, Int, DeclarationContext) throws -> (String, AnyObject)) {
		lock.lock()
		defer {
			lock.unlock()
		}
		let repositorySection = RepositorySection(itemFactory: itemFactory)
		for name in section.components(separatedBy: CharacterSet.whitespaces) {
			sectionByName[name] = repositorySection
		}
	}


	open func findDefinition(for item: String, in section: String, bundle: Bundle?) throws -> AnyObject? {
		lock.lock()
		defer {
			lock.unlock()
		}

		guard let section = sectionByName[section] else {
			return nil
		}

		if let item = section.itemByName[item] {
			return item
		}

		var resolvedBundle: Bundle
		if bundle != nil {
			resolvedBundle = bundle!
		}
		else {
			let nameParts = item.components(separatedBy: ".")
			resolvedBundle = nameParts.count > 1 ? Bundle.requiredFromModuleName(nameParts[0]) : Bundle.main
		}

		try loadRepositories(bundle: resolvedBundle)
		return section.itemByName[item]
	}



	open func findDefinition(for type: AnyObject.Type, with suffix: String?, in section: String) throws -> AnyObject? {
		let itemName = suffix == nil ? makeTypeName(forType: type) : "\(makeTypeName(forType: type)).\(suffix!)"
		return try findDefinition(for: itemName, in: section, bundle: nil)
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
					optionalCentralUI?.push(alert: .error, message: error.userDescription)
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
	private var sectionByName = [String: RepositorySection]()
	private var lock = NSRecursiveLock()


	private func makeTypeName(forType type: AnyObject.Type) -> String {
		return String(reflecting: type)
	}



	private func makeFragmentName(forModelType modelType: AnyObject.Type, name: String?) -> String {
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
		try loadRepository(elements: elements, context: context, overrideExisting: true)
	}


	private func loadRepositories(bundle: Bundle) throws {
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
			try loadRepository(elements: elements, context: context, overrideExisting: false)
		}
	}



	private func loadElement(section: RepositorySection, element: DeclarationElement, startAttribute: Int, context: DeclarationContext, overrideExisting: Bool) throws {
		context.reset()
		let (name, item) = try section.itemFactory(element, startAttribute, context)
		if overrideExisting || section.itemByName[name] == nil {
			section.itemByName[name] = item
		}
	}


	private static var itemFactoryBySectionName = [String: (DeclarationElement, Int, DeclarationContext) throws -> (String, AnyObject)]()

	public static func register(section: String, itemFactory: @escaping (DeclarationElement, Int, DeclarationContext) throws -> (String, AnyObject)) {
		itemFactoryBySectionName[section] = itemFactory
	}

	private func loadRepository(elements: [DeclarationElement], context: DeclarationContext, overrideExisting: Bool) throws {
		for element in elements {
			guard let section = sectionByName[element.name] else {
				continue
			}
			if (element.attributes.count == 1) || element.attributes[0].value.isMissing {
				for itemElement in element.children {
					try loadElement(section: section, element: itemElement, startAttribute: 0, context: context, overrideExisting: overrideExisting)
				}
			}
			else {
				try loadElement(section: section, element: element, startAttribute: 1, context: context, overrideExisting: overrideExisting)
			}
		}
	}



	private func bundle(forType type: AnyObject.Type) -> Bundle {
		let typeName = makeTypeName(forType: type)
		let typeNameParts = typeName.components(separatedBy: ".")
		return typeNameParts.count > 1 ? Bundle.requiredFromModuleName(typeNameParts[0]) : Bundle(for: type)
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
