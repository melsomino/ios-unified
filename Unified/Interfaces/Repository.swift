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

	func layoutFactory(forUi ui: AnyObject, name: String?) throws -> LayoutItemFactory
}


public let RepositoryDependency = Dependency<Repository>()



public protocol RepositoryDependent: Dependent {
}

extension RepositoryDependent {
	public var repository: Repository {
		return dependency.required(RepositoryDependency)
	}
	public var optionalRepository: Repository? {
		return dependency.optional(RepositoryDependency)
	}
}
