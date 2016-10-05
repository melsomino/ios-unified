//
// Created by Michael Vlasov on 13.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

open class DefaultExecutionControl: ExecutionControl {

	init(_ execution: DefaultExecution) {
		self.execution = execution
	}

	open func cancel() {
		execution.cancel()
	}

	open var complete: Bool {
		return execution.complete
	}

	fileprivate let execution: DefaultExecution
}
