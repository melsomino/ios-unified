//
// Created by Michael Vlasov on 30.07.16.
//

import Foundation





open class AsyncExecution {
	open var cancelled = false

	public final func then(on target: AsyncExecutionTarget, work: @escaping (AsyncExecution, AnyObject?) throws -> Void) -> AsyncExecution {
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
	private var error: Error?

	var errorHandler: ((AnyObject?, Error) -> Void)?
	var errorHandlerTarget = AsyncExecutionTarget.background

	var alwaysHandler: ((AnyObject?) -> Void)?
	var alwaysHandlerTarget = AsyncExecutionTarget.background

	var withOwner: Bool
	weak var owner: AnyObject?


	final func enqueue(_ work: AsyncWork) {
		planned.append(work)
	}

	final func setError(_ work: AsyncWork, error: Error) {
		self.error = error
		running.removeAll(keepingCapacity: false)
		planned.removeAll(keepingCapacity: false)
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

	final func setComplete(_ work: AsyncWork) {
		guard let running_index = running.index(where: { work === $0 }) else {
			return
		}
		running.remove(at: running_index)
		guard running.count == 0 else {
			return
		}
		running = planned
		planned.removeAll(keepingCapacity: true)
		for work in running {
			work.run()
		}
	}

	final func startPlanned() {
		running = planned
		planned.removeAll(keepingCapacity: true)
		for work in running {
			work.start()
		}
	}


}


