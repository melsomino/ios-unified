//
// Created by Michael Vlasov on 30.07.16.
//

import Foundation





public class AsyncQueue {
	private var operationQueue = NSOperationQueue()
}





public enum AsyncExecutionTarget {
	case ui
	case background
	case queue(AsyncQueue)
}





class AsyncHandler {
	let execution: AsyncExecution
	let target: AsyncExecutionTarget

	init(execution: AsyncExecution, target: AsyncExecutionTarget) {
		self.execution = execution
		self.target = target
	}


	final func start() {
		switch target {
			case .ui:
				start(on: NSOperationQueue.mainQueue())
			case .background:
				start(on: NSOperationQueue())
			case .queue(let queue):
				start(on: queue.operationQueue)
		}
	}


	final func start(on operationQueue: NSOperationQueue) {
		operationQueue.addOperationWithBlock {
			self.run()
		}
	}


	func run() {
		let owner = execution.owner
		if execution.withOwner && owner == nil {
			return
		}
		do {
			try doWork(execution, with: owner)
			onComplete()
		} catch let error {
			onError(error)
		}
	}


	func onError(error: ErrorType) {
	}


	func onComplete() {

	}


	func doWork(execution: AsyncExecution, with owner: AnyObject!) throws {

	}

}





class AsyncErrorHandler: AsyncHandler {

	private let handler: (AnyObject!, ErrorType) -> Void
	private let error: ErrorType

	init(execution: AsyncExecution, target: AsyncExecutionTarget, error: ErrorType, handler: (AnyObject!, ErrorType) -> Void) {
		self.handler = handler
		self.error = error
		super.init(execution: execution, target: target)
	}


	override func onComplete() {
		execution.setFinished()
	}


	override func doWork(execution: AsyncExecution, with owner: AnyObject!) throws {
		handler(owner, error)
	}

}





class AsyncAlwaysHandler: AsyncHandler {

	private let handler: (AnyObject!) -> Void

	init(execution: AsyncExecution, target: AsyncExecutionTarget, handler: (AnyObject?) -> Void) {
		self.handler = handler
		super.init(execution: execution, target: target)
	}


	override func doWork(execution: AsyncExecution, with owner: AnyObject?) throws {
		handler(owner)
	}

}


