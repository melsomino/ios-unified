//
// Created by Власов М.Ю. on 13.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation

public protocol Threading {
	var uiQueue: ExecutionQueue { get }
	var backgroundQueue: ExecutionQueue { get }
	func createQueue() -> ExecutionQueue
}

public let ThreadingDependency = Dependency<Threading>()

public extension DependencyResolver {
	public var threading: Threading {
		return required(ThreadingDependency)
	}
}