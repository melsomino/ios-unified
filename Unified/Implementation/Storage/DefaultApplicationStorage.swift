//
// Created by Власов М.Ю. on 17.05.16.
//

import Foundation


open class DefaultApplicationStorage: ApplicationStorage, ThreadingDependent {


	// MARK: - ApplicationStorage


	open func switchToAccount(_ accountName: String?) {
		self.accountName = accountName
		for (_, moduleStorage) in moduleStorages {
			moduleStorage.switchToAccount(accountName)
		}
	}


	open func getModuleStorage(_ moduleName: String) -> ModuleStorage {
		if let existing = moduleStorages[moduleName] {
			return existing
		}
		let moduleStorage = DefaultModuleStorage(moduleName: moduleName)
		moduleStorage.switchToAccount(accountName)
		moduleStorages[moduleName] = moduleStorage
		return moduleStorage
	}


	// MARK: - DependentObject


	open var dependency: DependencyResolver!


	// MARK: - Internals


	private var moduleStorages = [String: DefaultModuleStorage]()
	private var accountName: String?

}



extension DependencyContainer {
	public func createDefaultApplicationStorage() {
		register(ApplicationStorageDependency, DefaultApplicationStorage())
	}
}
