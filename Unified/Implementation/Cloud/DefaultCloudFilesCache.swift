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


	public func getFile(forUrl url: NSURL, forceExtension: String?) -> CloudFile {
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


	private var cloudConnector: CloudConnector
	private var localPath: String
	private var fileFromRelativeUrlHash = [String: DefaultCloudFile]()
	private var lock = NSLock()

	private func calcHash(url: String) -> String {
		return StringHashes.getHash(url)
	}

	private func getFileExtension(url: NSURL) -> String {
		let path = url.absoluteString
		guard let lastDotPos = path.rangeOfString(".", options: .BackwardsSearch) else {
			return ""
		}
		let ext = path.substringFromIndex(lastDotPos.startIndex)
		return ext.characters.count < 6 ? ext : ""
	}

}
