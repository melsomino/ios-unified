//
// Created by Michael Vlasov on 15.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation

public class DependencyError: ErrorType {
	public let message: String

	init(_ message: String) {
		self.message = message
	}
}


class DependencyRegistration<Interface>: DependentObject {
	private var sync = FastLock()
	private let factory: (() -> Interface)?
	private var implementation: Interface?

	init(_ factory: () -> Interface) {
		self.factory = factory
	}

	init(_ implementation: Interface) {
		self.factory = nil
		self.implementation = implementation
	}

	func resolveDependency(dependency: DependencyResolver) {
		if let dependent = implementation as? DependentObject {
			dependent.resolveDependency(dependency)
		}
	}
}


public class DependencyContainer: DependencyResolver {

	public init() {

	}

	public func register<Interface>(dependency: Dependency<Interface>, _ implementation: Interface) {
		sync.lock()
		setRegistration(DependencyRegistration<Interface>(implementation), at: dependency.index)
		sync.unlock()
		if resolveOnRegisterLock == 0 {
			if let dependent = implementation as? DependentObject {
				dependent.resolveDependency(self)
			}
		}
	}





	public func register<Interface>(dependency: Dependency<Interface>, _ factory: () -> Interface) {
		sync.lock()
		setRegistration(DependencyRegistration<Interface>(factory), at: dependency.index)
		sync.unlock()
	}


	public func createComponents(creation: (DependencyContainer) -> Void) {
		sync.lock()
		resolveOnRegisterLock += 1
		sync.unlock()
		creation(self)
		var dependents = [DependentObject]()
		sync.lock()
		resolveOnRegisterLock -= 1
		if resolveOnRegisterLock == 0 {
			for index in 0 ..< registrations.count {
				if let dependent = registrations[index] as? DependentObject {
					dependents.append(dependent)
				}
			}
		}
		sync.unlock()
		for dependent in dependents {
			dependent.resolveDependency(self)
		}
	}

	// MARK: - DependencyResolver


	public func optional<Interface>(component: Dependency<Interface>) -> Interface? {
		guard component.index < registrations.count else {
			return nil
		}
		guard let registrationObject = registrations[component.index] else {
			return nil
		}

		let registration = registrationObject as! DependencyRegistration<Interface>

		if registration.implementation == nil {
			registration.sync.lock()
			if registration.implementation == nil {
				registration.implementation = registration.factory!()
				if let dependent = registration.implementation as? DependentObject {
					dependent.resolveDependency(self)
				}
			}
			registration.sync.unlock()
		}

		return registration.implementation
	}





	public func required<Interface>(component: Dependency<Interface>) -> Interface {
		let implementation = optional(component)
		if implementation != nil {
			return implementation!
		}
		fatalError("Can not resolve dependency for interface \"\(String(Interface.self))\"")
	}


	// MARK: - Internals



	private var sync = FastLock()
	private var resolveOnRegisterLock = 0
	private var registrations = [AnyObject?]()

	private func setRegistration<Interface>(registration: DependencyRegistration<Interface>, at index: Int) {
		while index >= registrations.count {
			registrations.append(nil)
		}
		registrations[index] = registration
	}

}
