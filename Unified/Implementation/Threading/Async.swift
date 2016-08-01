//
// Created by Michael Vlasov on 29.07.16.
//

import Foundation









public class Async {
	public static func on(target: AsyncExecutionTarget, with owner: AnyObject?, work: (AsyncExecution, AnyObject?) throws -> Void) -> AsyncExecutionControl {
		let executionControl = AsyncExecutionControl(execution: AsyncExecution(owner: owner))
		executionControl.then(on: target, work: work)
		return executionControl
	}
}







