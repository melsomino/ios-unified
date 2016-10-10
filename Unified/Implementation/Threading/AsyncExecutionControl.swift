//
// Created by Michael Vlasov on 30.07.16.
//

import Foundation





open class AsyncExecutionControl {
	private let execution: AsyncExecution

	init(execution: AsyncExecution) {
		self.execution = execution
	}


	public final func then(on target: AsyncExecutionTarget, work: @escaping (AsyncExecution, AnyObject?) throws -> Void) -> AsyncExecutionControl {
		execution.then(on: target, work: work)
		return self
	}


	public final func catchError(on target: AsyncExecutionTarget, handler: @escaping (AnyObject?, Error) -> Void) -> AsyncExecutionControl {
		execution.errorHandlerTarget = target
		execution.errorHandler = handler
		return self
	}


	public final func always(on target: AsyncExecutionTarget, handler: @escaping (AnyObject?) -> Void) -> AsyncExecutionControl {
		execution.alwaysHandlerTarget = target
		execution.alwaysHandler = handler
		return self
	}


	public final func start() {
		execution.startPlanned()
	}
}





