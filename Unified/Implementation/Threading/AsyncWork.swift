//
// Created by Michael Vlasov on 30.07.16.
//

import Foundation





class AsyncWork: AsyncHandler {
	fileprivate var work: (AsyncExecution, AnyObject?) throws -> Void

	init(execution: AsyncExecution, target: AsyncExecutionTarget, work: @escaping (AsyncExecution, AnyObject?) throws -> Void) {
		self.work = work
		super.init(execution: execution, target: target)
	}


	// MARK: - Internals

	override func onError(_ error: Error) {
		execution.setError(self, error: error)
	}


	override func onComplete() {
		execution.setComplete(self)
	}

	override func doWork(_ execution: AsyncExecution, with owner: AnyObject?) throws {
		try work(execution, owner)
	}
}



