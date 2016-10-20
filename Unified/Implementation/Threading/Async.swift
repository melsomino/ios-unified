//
// Created by Michael Vlasov on 29.07.16.
//

import Foundation





open class Async {
	open static func on(_ target: AsyncExecutionTarget, with owner: AnyObject?, work: @escaping (AsyncExecution, AnyObject?) throws -> Void) -> AsyncExecutionControl {
		let executionControl = AsyncExecutionControl(execution: AsyncExecution(owner: owner))
		return executionControl.then(on: target, work: work)
	}
}







