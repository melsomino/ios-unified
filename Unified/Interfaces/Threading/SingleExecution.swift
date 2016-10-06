//
// Created by Michael Vlasov on 13.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

open class SingleExecution {

	public init(_ threading: Threading) {
		self.threading = threading
	}

	deinit {
		cancel()
	}

	open func cancel() {
		if current != nil {
			current!.cancel()
			current = nil
		}
	}

	open func onQueue(_ queue: ExecutionQueue, _ action: @escaping (Execution) throws -> Void) {
		cancel()
		current = queue.newExecution(action)
	}

	open func inBackground(_ action: @escaping (Execution) throws -> Void) {
		onQueue(threading.backgroundQueue, action)
	}


	// MARK: - Internals


	fileprivate let threading: Threading
	fileprivate var current: ExecutionControl?
}
