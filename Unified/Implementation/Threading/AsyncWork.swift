//
// Created by Michael Vlasov on 30.07.16.
//

import Foundation





class AsyncWork: AsyncHandler {
	private var work: (AsyncExecution, AnyObject?) throws -> Void

	init(execution: AsyncExecution, target: AsyncExecutionTarget, work: (AsyncExecution, AnyObject?) throws -> Void) {
		self.work = work
		super.init(execution: execution, target: target)
	}


	// MARK: - Internals

	override func onError(error: ErrorType) {
		execution.setError(self, error: error)
	}


	override func onComplete() {
		execution.setComplete(self)
	}

	override func doWork(execution: AsyncExecution, with owner: AnyObject?) throws {
		try work(execution, owner)
	}
}



