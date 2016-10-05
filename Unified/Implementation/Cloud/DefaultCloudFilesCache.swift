//
// Created by Michael Vlasov on 25.05.16.
//

import Foundation

open class DefaultCloudFilesCache: CloudFileCache {
	init(cloudConnector: CloudConnector, localPath: String) {
		self.cloudConnector = cloudConnector
		self.localPath = localPath
	}


	// MARK: - CloudFilesCache


	open func getFile(forUrl url: URL, forceExtension: String?) -> CloudFile {
		lock.lock()
		defer {
			lock.unlock()
		}
		let relativeUrlHash = calcHash(url.absoluteString)
		if let existing = fileFromRelativeUrlHash[relativeUrlHash] {
			return existing
		}
		let fileExtension = forceExtension != nil ? forceExtension! : getFileExtension(url)
		let localFilePath = "\(localPath)/\(relativeUrlHash)\(fileExtension)"
		let newFile = DefaultCloudFile(cloudConnector: cloudConnector, url: url, localPath: localFilePath)
		fileFromRelativeUrlHash[relativeUrlHash] = newFile
		return newFile
	}


	// MARK: - Internals


	fileprivate var cloudConnector: CloudConnector
	fileprivate var localPath: String
	fileprivate var fileFromRelativeUrlHash = [String: DefaultCloudFile]()
	fileprivate var lock = NSLock()

	fileprivate func calcHash(_ url: String) -> String {
		return StringHashes.getHash(url)
	}

	fileprivate func getFileExtension(_ url: URL) -> String {
		let path = url.absoluteString
		guard let lastDotPos = path.range(of: ".", options: .backwards) else {
			return ""
		}
		let ext = path.substring(from: lastDotPos.lowerBound)
		return ext.characters.count < 6 ? ext : ""
	}

}
