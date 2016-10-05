//
// Created by Michael Vlasov on 30.07.16.
//

import Foundation





open class AsyncQueue {
	fileprivate var operationQueue = OperationQueue()
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
				start(on: OperationQueue.main)
			case .background:
				start(on: OperationQueue())
			case .queue(let queue):
				start(on: queue.operationQueue)
		}
	}


	final func start(on operationQueue: OperationQueue) {
		operationQueue.addOperation {
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


	func onError(_ error: Error) {
	}


	func onComplete() {

	}


	func doWork(_ execution: AsyncExecution, with owner: AnyObject!) throws {

	}

}





class AsyncErrorHandler: AsyncHandler {

	fileprivate let handler: (AnyObject?, Error) -> Void
	fileprivate let error: Error

	init(execution: AsyncExecution, target: AsyncExecutionTarget, error: Error, handler: @escaping (AnyObject?, Error) -> Void) {
		self.handler = handler
		self.error = error
		super.init(execution: execution, target: target)
	}


	override func onComplete() {
		execution.setFinished()
	}


	override func doWork(_ execution: AsyncExecution, with owner: AnyObject!) throws {
		handler(owner, error)
	}

}





class AsyncAlwaysHandler: AsyncHandler {

	fileprivate let handler: (AnyObject!) -> Void

	init(execution: AsyncExecution, target: AsyncExecutionTarget, handler: @escaping (AnyObject?) -> Void) {
		self.handler = handler
		super.init(execution: execution, target: target)
	}


	override func doWork(_ execution: AsyncExecution, with owner: AnyObject?) throws {
		handler(owner)
	}

}


