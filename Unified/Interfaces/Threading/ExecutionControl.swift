//
// Created by Michael Vlasov on 13.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public protocol ExecutionControl {
	func cancel()
	var complete: Bool { get }
}
