//
// Created by Michael Vlasov on 15.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation

open class DependencyError: Error {
	open let message: String

	init(_ message: String) {
		self.message = message
	}
}


private protocol DependencyRegistrationEntry: class {
	func resolveImplementation(_ dependency: DependencyResolver)
}

class DependencyRegistration<Interface>: DependencyRegistrationEntry {
	var sync = FastLock()
	fileprivate let factory: (() -> Interface)?
	fileprivate var implementation: Interface?

	init(_ factory: @escaping () -> Interface) {
		self.factory = factory
	}

	init(_ implementation: Interface) {
		self.factory = nil
		self.implementation = implementation
	}

	func resolveImplementation(_ dependency: DependencyResolver) {
		if var dependent = implementation as? Dependent {
			dependent.dependency = dependency
		}
	}

}


open class DependencyContainer: DependencyResolver {

	public init() {

	}


	public convenience init(initialComponentsFactory: (DependencyContainer) -> Void) {
		self.init()
		createComponents(initialComponentsFactory)
	}


	open func register<Interface>(_ dependency: Dependency<Interface>, _ implementation: Interface) {
		sync.lock()
		setRegistration(DependencyRegistration<Interface>(implementation), at: dependency.index)
		sync.unlock()
		if resolveOnRegisterLock == 0 {
			resolve(implementation)
		}
	}





	open func register<Interface>(_ dependency: Dependency<Interface>, _ factory: @escaping () -> Interface) {
		sync.lock()
		setRegistration(DependencyRegistration<Interface>(factory), at: dependency.index)
		sync.unlock()
	}


	open func createComponents(_ creation: (DependencyContainer) -> Void) {
		sync.lock()
		resolveOnRegisterLock += 1
		sync.unlock()
		creation(self)
		var resolveQueue = [DependencyRegistrationEntry]()
		sync.lock()
		resolveOnRegisterLock -= 1
		if resolveOnRegisterLock == 0 {
			for i in 0 ..< registrations.count {
				if let registration = registrations[i] {
					resolveQueue.append(registration)
				}
			}
		}
		sync.unlock()
		for registration in resolveQueue {
			registration.resolveImplementation(self)
		}
	}

	// MARK: - DependencyResolver


	open func optional<Interface>(_ component: Dependency<Interface>) -> Interface? {
		guard component.index < registrations.count else {
			return nil
		}
		guard let registrationEntry = registrations[component.index] else {
			return nil
		}

		let registration = registrationEntry as! DependencyRegistration<Interface>

		if registration.implementation == nil {
			registration.sync.lock()
			if registration.implementation == nil {
				registration.implementation = registration.factory!()
				if var dependent = registration.implementation as? Dependent {
					dependent.dependency = self
				}
			}
			registration.sync.unlock()
		}

		return registration.implementation
	}





	open func required<Interface>(_ component: Dependency<Interface>) -> Interface {
		let implementation = optional(component)
		if implementation != nil {
			return implementation!
		}
		fatalError("Can not resolve dependency for interface \"\(String(describing: Interface.self))\"")
	}


	// MARK: - Internals



	private var sync = FastLock()
	private var resolveOnRegisterLock = 0
	private var registrations = [DependencyRegistrationEntry?]()

	private func setRegistration<Interface>(_ registration: DependencyRegistration<Interface>, at index: Int) {
		while index >= registrations.count {
			registrations.append(nil)
		}
		registrations[index] = registration
	}

}
