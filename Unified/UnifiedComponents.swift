//
// Created by Michael Vlasov on 26.05.16.
//

import Foundation
import  UIKit


extension DependencyContainer {
	public func createDefaultUnifiedComponents(server_host_domain: String) {
		createDefaultThreading()
		createDefaultCloudConnector(NSURL(string: "https://\(server_host_domain)")!)
		createDefaultApplicationStorage()
		createDefaultRepository()
	}
}

