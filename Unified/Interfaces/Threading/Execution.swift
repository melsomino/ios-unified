//
// Created by Власов М.Ю. on 13.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation

public protocol Execution {
	var cancelled: Bool { get }
	func continueOnUiQueue(action: () -> Void)
	func continueInBackground(action: () -> Void)
	func onCancel(handler: () -> Void)

	func reportComplete()
}
