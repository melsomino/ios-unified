//
// Created by Michael Vlasov on 13.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public protocol Threading {
	var uiQueue: ExecutionQueue { get }
	var backgroundQueue: ExecutionQueue { get }
	func createQueue() -> ExecutionQueue
}

public let ThreadingDependency = Dependency<Threading>()

public protocol ThreadingDependent: Dependent {

}
public extension ThreadingDependent {
	public var threading: Threading {
		return dependency.required(ThreadingDependency)
	}
	public var optionalThreading: Threading? {
		return dependency.optional(ThreadingDependency)
	}
}