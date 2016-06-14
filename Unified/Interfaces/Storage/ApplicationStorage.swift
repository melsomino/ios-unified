//
// Created by Michael Vlasov on 17.05.16.
//

import Foundation

public protocol ApplicationStorage {
	func switchToAccount(accountName: String?)
	func getModuleStorage(moduleName: String) -> ModuleStorage
}


public let ApplicationStorageDependency = Dependency<ApplicationStorage>()

extension DependencyResolver {
	public var applicationStorage: ApplicationStorage {
		return required(ApplicationStorageDependency)
	}
}
