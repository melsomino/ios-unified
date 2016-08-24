//
// Created by Michael Vlasov on 12.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public class CloudError: ErrorType, CustomStringConvertible, CustomDebugStringConvertible {
	public let message: String?
	public let source: Any?

	public init (_ message: String, _ source: Any?) {
		self.message = message
		self.source = source
	}

	public var description: String {
		if let error = source as? NSError {
			return "Ошибка сервера: \(error.domain)"
		}
		return message ?? ""
	}

	public var debugDescription: String {
		if let error = source as? NSError {
			return "Ошибка сервера: \(error)"
		}
		return message ?? ""
	}

}


