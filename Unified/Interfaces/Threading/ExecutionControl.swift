//
// Created by Власов М.Ю. on 13.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation

public protocol ExecutionControl {
	func cancel()
	var complete: Bool { get }
}
