//
// Created by Власов М.Ю. on 17.05.16.
//

import Foundation


public class DefaultApplicationStorage: ApplicationStorage, DependentObject, LogonListener {


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
		logon?.addListener(self)
	}


	// MARK: - LogonListener


	public func onLogin() {
		switchToAccount(logon?.currentAccount)
	}


	public func onLogout() {
		switchToAccount(logon?.currentAccount)
	}


	// MARK: - Internals


	private var dependency: DependencyResolver!

	private var threading: Threading! {
		return dependency.threading
	}

	private var logon: LogonModule! {
		return dependency.optionalLogonModule
	}

	private var moduleStorages = [String: DefaultModuleStorage]()
	private var accountName: String?

}
