//
// Created by Власов М.Ю. on 13.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation

public protocol ExecutionQueue {
	func newExecution(action: (Execution) throws -> Void) -> ExecutionControl
	func continueExecution(execution: Execution, _ action: () throws  -> Void)
}
