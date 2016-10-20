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


public extension Threading {

	public final func inBackground<Owner:AnyObject>(with owner: Owner, work: @escaping (Owner, Execution) throws -> Void, onComplete: @escaping (Owner) -> Void, onError: @escaping (Owner, Error) -> Void) {
		weak var weakOwner: Owner? = owner
		let _ = backgroundQueue.newExecution {
			execution in
			do {
				if let strongOwner = weakOwner {
					try work(strongOwner, execution)
				}
				if weakOwner == nil {
					return
				}
				execution.continueOnUiQueue {
					if let strongOwner = weakOwner {
						onComplete(strongOwner)
					}
				}
			}
				catch let error {
				execution.continueOnUiQueue {
					if let strongOwner = weakOwner {
						onError(strongOwner, error)
					}
				}
			}
		}
	}

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
