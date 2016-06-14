//
// Created by Власов М.Ю. on 12.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation


public protocol CloudConnector {
	func makeUrl(relativePath: String) -> NSURL
	func invokeService(serviceUrl: NSURL, _ protocolVersion: Int, _ method: String, _ params: AnyObject) throws -> AnyObject

	func getFileCache(localPath: String) -> CloudFileCache
}

public let CloudConnectorDependency = Dependency<CloudConnector>()


public extension DependencyResolver {
	public var cloudConnector: CloudConnector {
		return required(CloudConnectorDependency)
	}
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





