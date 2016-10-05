//
// Created by Michael Vlasov on 13.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public protocol ExecutionQueue {
	func newExecution(_ action: @escaping (Execution) throws -> Void) -> ExecutionControl
	func continueExecution(_ execution: Execution, _ action: @escaping () throws  -> Void)
}
