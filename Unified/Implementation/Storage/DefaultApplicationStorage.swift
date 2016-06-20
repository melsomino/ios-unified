//
// Created by Власов М.Ю. on 17.05.16.
//

import Foundation


public class DefaultApplicationStorage: ApplicationStorage, Dependent {


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


	public var dependency: DependencyResolver!


	// MARK: - Internals


	private var threading: Threading! {
		return dependency.threading
	}

	private var moduleStorages = [String: DefaultModuleStorage]()
	private var accountName: String?

}
