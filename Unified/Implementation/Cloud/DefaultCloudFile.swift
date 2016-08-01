//
// Created by Michael Vlasov on 25.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation





public class DefaultCloudFile: CloudFile {
	init(cloudConnector: CloudConnector, relativeUrl: String, localPath: String) {
		self.cloudConnector = cloudConnector
		self.url = cloudConnector.makeUrl(relativeUrl)
		self.localPath = localPath

		if NSFileManager.defaultManager().fileExistsAtPath(localPath) {
			_state = .Loaded
		}
		else {
			startDownload()
		}
	}


	// MARK: - CloudFile


	public func addListener(listener: CloudFileListener) {
		lock.withLock {
			self.listeners.add(listener)
		}
	}


	public func removeListener(listener: CloudFileListener) {
		lock.withLock {
			self.listeners.remove(listener)
		}
	}


	public var state: CloudFileState {
		return lock.locked {
			self._state
		}
	}


	public var localPath: String


	// MARK: - Internals


	private let cloudConnector: CloudConnector
	private let url: NSURL
	private var listeners = ListenerList<CloudFileListener>()
	private var lock = FastLock()
	private var _state = CloudFileState.Loading


	private func setState(newState: CloudFileState) {
		let liveListeners: [CloudFileListener] = lock.locked {
			self._state = newState
			return self.listeners.getLive()
		}

		for listener in liveListeners {
			listener.cloudFileStateChanged(self)
		}
	}


	private func startDownload() {
		weak var weakSelf = self

		let request = NSURLRequest(URL: url)
		cloudConnector.startDownload(request,
			progress: nil,
			error: {
				error in
				guard let strongSelf = weakSelf else {
					return
				}
				strongSelf.setState(.Failed(error))
			}) {
			downloadedUrl in
			guard let strongSelf = weakSelf else {
				return
			}
			do {
				let downloadedPath = downloadedUrl.path!
				try NSFileManager.defaultManager().copyItemAtPath(downloadedPath, toPath: strongSelf.localPath)
				strongSelf.setState(.Loaded)
			} catch let error {
				strongSelf.setState(.Failed(CloudError("Ошибка загрузки файла", error)))
			}
		}
	}
}




