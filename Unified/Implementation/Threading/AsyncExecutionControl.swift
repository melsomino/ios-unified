//
// Created by Michael Vlasov on 30.07.16.
//

import Foundation





public class AsyncExecutionControl {
	private let execution: AsyncExecution

	init(execution: AsyncExecution) {
		self.execution = execution
	}


	public final func then(on target: AsyncExecutionTarget, work: (AsyncExecution, AnyObject?) throws -> Void) -> AsyncExecutionControl {
		execution.then(on: target, work: work)
		return self
	}


	public final func catchError(on target: AsyncExecutionTarget, handler: (AnyObject?, ErrorType) -> Void) -> AsyncExecutionControl {
		execution.errorHandlerTarget = target
		execution.errorHandler = handler
		return self
	}


	public final func always(on target: AsyncExecutionTarget, handler: (AnyObject?) -> Void) -> AsyncExecutionControl {
		execution.alwaysHandlerTarget = target
		execution.alwaysHandler = handler
		return self
	}


	public final func start() {
		execution.startPlanned()
	}
}





