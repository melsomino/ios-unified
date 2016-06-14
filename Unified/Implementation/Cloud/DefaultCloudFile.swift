//
// Created by Власов М.Ю. on 25.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation

public class DefaultCloudFile: CloudFile {
	init(url: NSURL, localPath: String) {
		self.url = url
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
		let httpSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
		weak var weakSelf = self

		httpSession.downloadTaskWithURL(url) {
			downloadedLocalUrl, httpResponse, httpError in
			guard let strongSelf = weakSelf else {
				return
			}

			var downloadError: CloudError?
			if httpError != nil {
				downloadError = CloudError("Ошибка загрузки файла", httpError)
			}
			do {
				let downloadedPath = downloadedLocalUrl!.path!
				try NSFileManager.defaultManager().copyItemAtPath(downloadedPath, toPath: self.localPath)
			}
			catch let error {
				downloadError = CloudError("Ошибка загрузки файла", error)
			}

			if downloadError != nil {
				strongSelf.setState(.Failed(downloadError!))
			}
			else {
				strongSelf.setState(.Loaded)
			}
		}
		.resume()
	}



}
