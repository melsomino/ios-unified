//
// Created by Власов М.Ю. on 26.05.16.
//

import Foundation
import SbisCore
import  UIKit


extension DependencyContainer {
	public func createDefaultUnifiedComponents(server_host_domain: String) {
		register(ThreadingDependency, DefaultThreading())
		register(CloudConnectorDependency, DefaultCloudConnector(baseUrl: NSURL(string: "https://\(server_host_domain)")!))
		register(ApplicationStorageDependency, DefaultApplicationStorage())
	}
}

