//
// Created by Michael Vlasov on 13.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

open class DefaultExecution : Execution {


	init(_ threading: DefaultThreading) {
		self.threading = threading
	}


	open func cancel() {
		cancelled = true
		cancellationHandler?()
	}


	// MARK: - Execution


	open var cancelled = false
	open var complete = false

	open func continueOnUiQueue(_ action: @escaping () -> Void) {
		threading.uiQueue.continueExecution(self, action)
	}


	open func continueInBackground(_ action: @escaping () -> Void) {
		threading.backgroundQueue.continueExecution(self, action)
	}

	open func onCancel(_ handler: @escaping () -> Void) {
		cancellationHandler = handler
	}

	open func reportComplete() {
		complete = true
	}


	// MARK: - Internals


	private weak var threading: DefaultThreading!
	private var cancellationHandler: (() -> Void)?

}
