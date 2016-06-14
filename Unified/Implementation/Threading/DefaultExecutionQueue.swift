//
// Created by Michael Vlasov on 13.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

class DefaultExecutionQueue: ExecutionQueue {


	init(_ threading: DefaultThreading, _ platformQueue: NSOperationQueue) {
		self.threading = threading
		self.platformQueue = platformQueue
	}


	// MARK: - ExecutionQueue


	func newExecution(action: (Execution) throws -> Void) -> ExecutionControl {
		let execution = DefaultExecution(threading)
		platformQueue.addOperationWithBlock() {
			if !execution.cancelled {
				do {
					try action(execution)
				}
					catch let error {
					print(error)
				}
			}
		}
		return DefaultExecutionControl(execution)
	}


	func continueExecution(execution: Execution, _ action: () throws -> Void) {
		platformQueue.addOperationWithBlock() {
			if !execution.cancelled {
				do {
					try action()
				}
					catch let error {
					print(error)
				}
			}
		}
	}


// MARK: - Internals


	private weak var threading: DefaultThreading!
	private let platformQueue: NSOperationQueue
}
