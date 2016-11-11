//
// Created by Michael Vlasov on 20.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation


public protocol RepositoryListener {
	func repositoryChanged(_ repository: Repository)
}


public protocol Repository: class {
	var devServerUrl: URL? { get set }

	func addListener(_ listener: RepositoryListener)
	func removeListener(_ listener: RepositoryListener)

	func load(repository name: String) throws -> [DeclarationElement]
	func load(repository name: String, forType: AnyObject.Type) throws -> [DeclarationElement]
	func load(declarations name: String, fromModuleWithType: AnyObject.Type) throws -> [DeclarationElement]

	func fragmentDefinition(forModelType modelType: AnyObject.Type, name: String?) throws -> FragmentDefinition

	func register(section: String, itemFactory: @escaping (DeclarationElement, Int, DeclarationContext) throws -> (String, AnyObject))

	func findDefinition(for item: String, in section: String, bundle: Bundle?) throws -> AnyObject?
	func findDefinition(for type: AnyObject.Type, with suffix: String?, in section: String) throws -> AnyObject?
}


public let RepositoryDefaultDevServerUrl = URL(string: "ws://localhost:8080/events")!

public let RepositoryDependency = Dependency<Repository>()



public protocol RepositoryDependent: Dependent {
}

extension RepositoryDependent {
	public var repository: Repository {
		return dependency.required(RepositoryDependency)
	}
	public var optionalRepository: Repository? {
		return dependency?.optional(RepositoryDependency)
	}
}
