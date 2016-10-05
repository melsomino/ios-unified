//
// Created by Michael Vlasov on 17.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

open class StorageError: Error {
	open let message: String

	init(message: String) {
		self.message = message
	}
}
