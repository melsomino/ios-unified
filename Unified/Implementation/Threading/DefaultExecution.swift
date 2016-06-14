//
// Created by Власов М.Ю. on 13.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation

public class DefaultExecution : Execution {


	init(_ threading: DefaultThreading) {
		self.threading = threading
	}


	public func cancel() {
		cancelled = true
		cancellationHandler?()
	}


	// MARK: - Execution


	public var cancelled = false
	public var complete = false

	public func continueOnUiQueue(action: () -> Void) {
		threading.uiQueue.continueExecution(self, action)
	}


	public func continueInBackground(action: () -> Void) {
		threading.backgroundQueue.continueExecution(self, action)
	}

	public func onCancel(handler: () -> Void) {
		cancellationHandler = handler
	}

	public func reportComplete() {
		complete = true
	}


	// MARK: - Internals


	private weak var threading: DefaultThreading!
	private var cancellationHandler: (() -> Void)?

}
