//
// Created by Власов М.Ю. on 17.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation

public class StorageError: ErrorType {
	public let message: String

	init(message: String) {
		self.message = message
	}
}
