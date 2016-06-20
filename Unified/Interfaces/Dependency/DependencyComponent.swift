//
// Created by Michael Vlasov on 26.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation


public class Dependency<Protocol> {

	public let index: Int

	public init() {
		_protocol_dependency_lock.lock()
		index = _protocol_dependency_count
		_protocol_dependency_count += 1
		_protocol_dependency_lock.unlock()
	}

	public func required(dependency: DependencyResolver) -> Protocol {
		return dependency.required(self)
	}

}

private var _protocol_dependency_lock = FastLock()
private var _protocol_dependency_count = 0
