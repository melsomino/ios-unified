//
// Created by Michael Vlasov on 25.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation





open class DefaultCloudFile: CloudFile {

	init(cloudConnector: CloudConnector, url: URL, localPath: String) {
		self.cloudConnector = cloudConnector
		self.url = url
		self.localPath = localPath

		if FileManager.default.fileExists(atPath: localPath) {
			_state = .loaded
		}
		else {
			startDownload()
		}
	}


	// MARK: - CloudFile


	open func addListener(_ listener: CloudFileListener) {
		lock.withLock {
			self.listeners.add(listener)
		}
	}


	open func removeListener(_ listener: CloudFileListener) {
		lock.withLock {
			self.listeners.remove(listener)
		}
	}


	open var state: CloudFileState {
		return lock.locked {
			self._state
		}
	}


	open var localPath: String


	// MARK: - Internals


	private let cloudConnector: CloudConnector
	private let url: URL
	private var listeners = ListenerList<CloudFileListener>()
	private var lock = FastLock()
	private var _state = CloudFileState.loading(0)


	private func setState(_ newState: CloudFileState) {
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

		let request = URLRequest(url: url)
		cloudConnector.startDownload(request,
			progress: {
				(downloaded, expected) in
				guard let strongSelf = weakSelf else {
					return
				}
				strongSelf.setState(.loading(expected > 0 ? Float(downloaded) / Float(expected) : 0.5))
			},
			error: {
				error in
				guard let strongSelf = weakSelf else {
					return
				}
				strongSelf.setState(.failed(error))
			}) {
			downloadedUrl in
			guard let strongSelf = weakSelf else {
				return
			}
			do {
				let downloadedPath = downloadedUrl.path
				try FileManager.default.copyItem(atPath: downloadedPath, toPath: strongSelf.localPath)
				strongSelf.setState(.loaded)
			} catch let error {
				strongSelf.setState(.failed(CloudError("Ошибка загрузки файла", error)))
			}
		}
	}
}




