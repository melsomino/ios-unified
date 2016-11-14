//
// Created by Michael Vlasov on 26.05.16.
//

import Foundation
import UIKit



public class UnifiedRuntime {
	public static func setup() {
		UnifiedUi.setup()
	}
}



extension DependencyContainer {
	public func createDefaultUnifiedComponents(_ server_host_domain: String) {
		createDefaultThreading()
		createDefaultCloudConnector(URL(string: "https://\(server_host_domain)")!)
		createDefaultApplicationStorage()
		createDefaultRepository()
	}
}

