//
// Created by Michael Vlasov on 13.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

class DefaultThreading: Threading {

	var uiQueue: ExecutionQueue {
		return DefaultExecutionQueue(self, OperationQueue.main)
	}

	var backgroundQueue: ExecutionQueue {
		return DefaultExecutionQueue(self, OperationQueue())
	}

	func createQueue() -> ExecutionQueue {
		return DefaultExecutionQueue(self, OperationQueue())
	}

}


extension DependencyContainer {
	public func createDefaultThreading() {
		register(ThreadingDependency, DefaultThreading())
	}
}


