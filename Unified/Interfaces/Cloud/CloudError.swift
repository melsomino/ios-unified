//
// Created by Michael Vlasov on 12.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

open class CloudError: Error, CustomStringConvertible, CustomDebugStringConvertible {
	open let message: String?
	open let source: Any?

	public init (_ message: String, _ source: Any?) {
		self.message = message
		self.source = source
	}

	open var description: String {
		if let error = source as? NSError {
			return "Ошибка сервера: \(error.domain)"
		}
		return message ?? ""
	}

	open var debugDescription: String {
		if let error = source as? NSError {
			return "Ошибка сервера: \(error)"
		}
		return message ?? ""
	}

}


