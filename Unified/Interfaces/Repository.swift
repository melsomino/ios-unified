//
// Created by Michael Vlasov on 20.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation


public protocol RepositoryListener {
	func repositoryChanged(repository: Repository)
}


public protocol Repository: class {
	var devServerUrl: NSURL? { get set }

	func addListener(listener: RepositoryListener)
	func removeListener(listener: RepositoryListener)

	func uiFactory(forModelType modelType: Any.Type, name: String?) throws -> UiDefinition

}


public let RepositoryDefaultDevServerUrl = NSURL(string: "ws://localhost:8080/events")!

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
