//
// Created by Michael Vlasov on 13.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public class SingleExecution {

	public init(_ threading: Threading) {
		self.threading = threading
	}

	deinit {
		cancel()
	}

	public func cancel() {
		if current != nil {
			current!.cancel()
			current = nil
		}
	}

	public func onQueue(queue: ExecutionQueue, _ action: (Execution) throws -> Void) {
		cancel()
		current = queue.newExecution(action)
	}

	public func inBackground(action: (Execution) throws -> Void) {
		onQueue(threading.backgroundQueue, action)
	}


	// MARK: - Internals


	private let threading: Threading
	private var current: ExecutionControl?
}
