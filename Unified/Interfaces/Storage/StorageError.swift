//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public class StorageError: ErrorType {
	public let message: String

	init(message: String) {
		self.message = message
	}
}
