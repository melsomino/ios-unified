//
// Created by Власов М.Ю. on 12.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation

public class CloudError: ErrorType, CustomStringConvertible, CustomDebugStringConvertible {
	public let message: String?
	public let source: Any?

	init (_ message: String, _ source: Any?) {
		self.message = message
		self.source = source
	}

	public var description: String {
		if let error = source as? NSError {
			return "Ошибка доступа к облаку: \(error.domain)"
		}
		return "Ошибка доступа к облаку: " + (message ?? "")
	}

	public var debugDescription: String {
		if let error = source as? NSError {
			return "Ошибка доступа к облаку: \(error)"
		}
		return "Ошибка доступа к облаку: " + (message ?? "")
	}

}


