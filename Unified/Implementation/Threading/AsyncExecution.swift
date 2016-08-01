//
// Created by Michael Vlasov on 30.07.16.
//

import Foundation





public class AsyncExecution {
	public var cancelled = false

	public final func then(on target: AsyncExecutionTarget, work: (AsyncExecution, AnyObject?) throws -> Void) -> AsyncExecution {
		enqueue(AsyncWork(execution: self, target: target, work: work))
		return self
	}


	init(owner: AnyObject?) {
		withOwner = owner != nil
		self.owner = owner
	}


	// MARK: - Internals


	private var planned = [AsyncWork]()
	private var running = [AsyncWork]()
	private var error: ErrorType?

	var errorHandler: ((AnyObject?, ErrorType) -> Void)?
	var errorHandlerTarget = AsyncExecutionTarget.background

	var alwaysHandler: ((AnyObject?) -> Void)?
	var alwaysHandlerTarget = AsyncExecutionTarget.background

	var withOwner: Bool
	weak var owner: AnyObject?


	final func enqueue(work: AsyncWork) {
		planned.append(work)
	}

	final func setError(work: AsyncWork, error: ErrorType) {
		self.error = error
		running.removeAll(keepCapacity: false)
		planned.removeAll(keepCapacity: false)
		guard let errorHandler = errorHandler else {
			return
		}
		AsyncErrorHandler(execution: self, target: errorHandlerTarget, error: error, handler: errorHandler).start()
	}

	final func setFinished() {
		guard let alwaysHandler = alwaysHandler else {
			return
		}
		AsyncAlwaysHandler(execution: self, target: alwaysHandlerTarget, handler: alwaysHandler).start()
	}

	final func setComplete(work: AsyncWork) {
		guard let running_index = running.indexOf({ work === $0 }) else {
			return
		}
		running.removeAtIndex(running_index)
		guard running.count == 0 else {
			return
		}
		running = planned
		planned.removeAll(keepCapacity: true)
		for work in running {
			work.run()
		}
	}

	final func startPlanned() {
		running = planned
		planned.removeAll(keepCapacity: true)
		for work in running {
			work.start()
		}
	}


}


