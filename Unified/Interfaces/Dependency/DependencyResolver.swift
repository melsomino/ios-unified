//
// Created by Michael Vlasov on 15.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation


public protocol DependencyResolver {
	func optional<Protocol>(component: Dependency<Protocol>) -> Protocol?
	func required<Protocol>(component: Dependency<Protocol>) -> Protocol
}


public protocol DependentObject {
	func resolveDependency(dependency: DependencyResolver)
}

public extension DependencyResolver {
	public func resolve(dependentObjects: DependentObject...) {
		for object in dependentObjects {
			object.resolveDependency(self)
		}
	}

}