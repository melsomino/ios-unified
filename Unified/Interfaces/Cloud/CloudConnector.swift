//
// Created by Michael Vlasov on 12.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public protocol CloudConnector {
	func makeUrl(_ relativePath: String) -> URL

	func invokeService(_ serviceUrl: URL, _ protocolVersion: Int, _ method: String, _ params: Any) throws -> Any
	func startDownload(_ request: URLRequest, progress: ((Int64, Int64) -> Void)?, error:  ((Error) -> Void)?, complete: @escaping (URL) -> Void)

	func getFileCache(_ localPath: String) -> CloudFileCache
}





public protocol CloudFileCache {
	func getFile(forUrl url: URL, forceExtension: String?) -> CloudFile
}





public protocol CloudFile {
	func addListener(_ listener: CloudFileListener)
	func removeListener(_ listener: CloudFileListener)

	var state: CloudFileState { get }
	var localPath: String { get }
}





public enum CloudFileState {
	case loading(Float)
	case loaded
	case failed(Error)
}





public protocol CloudFileListener: class {
	func cloudFileStateChanged(_ file: CloudFile)
}





public let CloudConnectorDependency = Dependency<CloudConnector>()

public protocol CloudConnectorDependent: Dependent {

}


public extension CloudConnectorDependent {
	public var optionalCloudConnector: CloudConnector? {
		return dependency.optional(CloudConnectorDependency)
	}

	public var cloudConnector: CloudConnector {
		return dependency.required(CloudConnectorDependency)
	}
}


