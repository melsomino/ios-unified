//
// Created by Michael Vlasov on 17.05.16.
//

import Foundation


public class DefaultApplicationStorage: ApplicationStorage, DependentObject {


	// MARK: - ApplicationStorage


	public func switchToAccount(accountName: String?) {
		self.accountName = accountName
		for (_, moduleStorage) in moduleStorages {
			moduleStorage.switchToAccount(accountName)
		}
	}


	public func getModuleStorage(moduleName: String) -> ModuleStorage {
		if let existing = moduleStorages[moduleName] {
			return existing
		}
		let moduleStorage = DefaultModuleStorage(moduleName: moduleName)
		moduleStorage.switchToAccount(accountName)
		moduleStorages[moduleName] = moduleStorage
		return moduleStorage
	}


	// MARK: - DependentObject


	public func resolveDependency(dependency: DependencyResolver) {
		self.dependency = dependency
	}


	// MARK: - Internals


	private var dependency: DependencyResolver!

	private var threading: Threading! {
		return dependency.threading
	}

	private var moduleStorages = [String: DefaultModuleStorage]()
	private var accountName: String?

}
