//
// Created by Michael Vlasov on 12.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation


public protocol CloudConnector {
	func makeUrl(relativePath: String) -> NSURL

	func invokeService(serviceUrl: NSURL, _ protocolVersion: Int, _ method: String, _ params: AnyObject) throws -> AnyObject
	func startDownload(request: NSURLRequest, progress: ((Int64, Int64) -> Void)?, error: ((ErrorType) -> Void)?, complete: (NSURL) -> Void)

	func getFileCache(localPath: String) -> CloudFileCache
}

public protocol CloudFileCache {
	func getFile(relativeUrl: String, forceExtension: String?) -> CloudFile
}





public protocol CloudFile {
	func addListener(listener: CloudFileListener)
	func removeListener(listener: CloudFileListener)

	var state: CloudFileState { get }
	var localPath: String { get }
}





public enum CloudFileState {
	case Loading, Loaded, Failed(ErrorType)
}





public protocol CloudFileListener: class {
	func cloudFileStateChanged(file: CloudFile)
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


