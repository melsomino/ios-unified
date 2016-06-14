//
// Created by Власов М.Ю. on 13.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation

class DefaultThreading: Threading {

	var uiQueue: ExecutionQueue {
		return DefaultExecutionQueue(self, NSOperationQueue.mainQueue())
	}

	var backgroundQueue: ExecutionQueue {
		return DefaultExecutionQueue(self, NSOperationQueue())
	}

	func createQueue() -> ExecutionQueue {
		return DefaultExecutionQueue(self, NSOperationQueue())
	}

}
