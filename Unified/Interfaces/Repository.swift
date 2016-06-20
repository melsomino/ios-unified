//
// Created by Michael Vlasov on 20.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation


public protocol RepositoryListener {
	func repositoryChanged(repository: Repository)
}

public protocol Repository {
	var devServerUrl: NSURL? { get set }

	func addListener(listener: RepositoryListener)
	func removeListener(listener: RepositoryListener)

	func createLayoutFor(ui: AnyObject) throws -> LayoutItem
}


public let RepositoryDependency = Dependency<Repository>()


extension DependencyResolver {
	public var repository: Repository {
		return required(RepositoryDependency)
	}
	public var optionalRepository: Repository? {
		return optional(RepositoryDependency)
	}
}
