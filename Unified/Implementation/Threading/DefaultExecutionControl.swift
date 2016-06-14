//
// Created by Michael Vlasov on 13.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public class DefaultExecutionControl: ExecutionControl {

	init(_ execution: DefaultExecution) {
		self.execution = execution
	}

	public func cancel() {
		execution.cancel()
	}

	public var complete: Bool {
		return execution.complete
	}

	private let execution: DefaultExecution
}
