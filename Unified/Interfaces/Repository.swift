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
	func load(repository name: String, forType: Any.Type) throws -> [DeclarationElement]
	func load(declarations name: String, fromModuleWithType: Any.Type) throws -> [DeclarationElement]

	func fragmentDefinition(forModelType modelType: Any.Type, name: String?) throws -> FragmentDefinition

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
