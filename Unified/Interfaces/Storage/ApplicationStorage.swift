//
// Created by Michael Vlasov on 17.05.16.
//

import Foundation

public protocol ApplicationStorage {
	func switchToAccount(accountName: String?)
	func getModuleStorage(moduleName: String) -> ModuleStorage
}


public let ApplicationStorageDependency = Dependency<ApplicationStorage>()

public protocol ApplicationStorageDependent: Dependent {
}

extension ApplicationStorageDependent {
	public var applicationStorage: ApplicationStorage {
		return dependency.required(ApplicationStorageDependency)
	}

	public var optionalApplicationStorage: ApplicationStorage? {
		return dependency.optional(ApplicationStorageDependency)
	}
}
