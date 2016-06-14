//
// Created by Michael Vlasov on 25.05.16.
//

import Foundation

public class DefaultCloudFilesCache: CloudFileCache {
	init(cloudConnector: CloudConnector, localPath: String) {
		self.cloudConnector = cloudConnector
		self.localPath = localPath
	}


	// MARK: - CloudFilesCache


	public func getFile(relativeUrl: String, forceExtension: String?) -> CloudFile {
		lock.lock()
		defer {
			lock.unlock()
		}
		let relativeUrlHash = calcHash(relativeUrl)
		if let existing = fileFromRelativeUrlHash[relativeUrlHash] {
			return existing
		}
		let localFilePath = localPath + "/" + relativeUrlHash + (forceExtension ?? "")
		let newFile = DefaultCloudFile(url: cloudConnector.makeUrl(relativeUrl), localPath: localFilePath)
		fileFromRelativeUrlHash[relativeUrlHash] = newFile
		return newFile
	}


	// MARK: - Internals


	private var cloudConnector: CloudConnector
	private var localPath: String
	private var fileFromRelativeUrlHash = [String: DefaultCloudFile]()
	private var lock = NSLock()

	private func calcHash(url: String) -> String {
		return StringHashes.getHash(url)
	}


}
