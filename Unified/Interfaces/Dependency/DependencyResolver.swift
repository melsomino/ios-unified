//
// Created by Michael Vlasov on 15.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation


public protocol DependencyResolver {
	func optional<Protocol>(component: Dependency<Protocol>) -> Protocol?
	func required<Protocol>(component: Dependency<Protocol>) -> Protocol
}


public protocol Dependent {
	var dependency: DependencyResolver! { get set }
}

public extension DependencyResolver {
	public func resolve(objects: Any...) {
		for object in objects {
			if var dependent = object as? Dependent {
				dependent.dependency = self
			}
		}
	}

}