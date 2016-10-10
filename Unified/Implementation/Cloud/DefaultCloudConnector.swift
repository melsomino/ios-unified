//
// Created by Michael Vlasov on 12.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation


open class DefaultCloudConnector: CloudConnector {

	open var debugResponseTracePath: String?

	public init(baseUrl: URL) {
		self.baseUrl = baseUrl
	}


	// MARK: - CloudConnector

	var urlSession: URLSession = URLSession(configuration: URLSessionConfiguration.default)


	open func getFileCache(_ localPath: String) -> CloudFileCache {
		if !sessionCacheLocalPaths.contains(localPath) {
			let fm = FileManager.default
			do {
				for file in try fm.contentsOfDirectory(atPath: localPath) {
					let _ = try? fm.removeItem(atPath: localPath + "/" + file)
				}
			}
			catch {
			}
			sessionCacheLocalPaths.insert(localPath)
		}
		return DefaultCloudFilesCache(cloudConnector: self, localPath: localPath)
	}



	open func makeUrl(_ relativePath: String) -> URL {
		return URL(string: relativePath, relativeTo: baseUrl)!
	}


	private class DownloadProgressReporter: NSObject, URLSessionDownloadDelegate {

		var progressHandler: ((Int64, Int64) -> Void)?
		var errorHandler: ((Error) -> Void)?
		var completionHandler: (URL) -> Void

		@objc func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
			completionHandler(location)
		}

		@objc func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
			if let handler = errorHandler {
				if let downloadError = error {
					handler(downloadError)
				}
			}
		}

		@objc func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
			if let handler = progressHandler {
				handler(totalBytesWritten, totalBytesExpectedToWrite)
			}
		}

		init(progress: ((Int64, Int64) -> Void)?,  error: ((Error) -> Void)?, completion: @escaping (URL) -> Void) {
			progressHandler = progress
			errorHandler = error
			completionHandler = completion
		}
	}

	open func startDownload(_ request: URLRequest, progress: ((Int64, Int64) -> Void)?, error: ((Error) -> Void)?, complete: @escaping (URL) -> Void) {
		let progressReporter = DownloadProgressReporter(progress: progress, error: error, completion: complete)
		progressReporter.progressHandler = progress
		let session = URLSession(configuration: urlSession.configuration, delegate: progressReporter, delegateQueue: OperationQueue())
		let task = session.downloadTask(with: request)
		task.resume()
	}



	open func invokeService(_ serviceUrl: URL, _ protocolVersion: Int, _ method: String, _ params: Any) throws -> Any {
		var json = [String: Any]()

		json["jsonrpc"] = "2.0"
		json["protocol"] = protocolVersion
		json["method"] = method
		json["params"] = params

		let httpRequest = NSMutableURLRequest(url: serviceUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60.0)
		let httpRequestJson = ["jsonrpc": "2.0", "protocol": protocolVersion, "method": method, "params": params] as [String : Any]
		let httpRequestData = try! JSONSerialization.data(withJSONObject: httpRequestJson, options: [])

		httpRequest.httpMethod = "POST"
		httpRequest.httpBody = httpRequestData
		httpRequest.addValue("application/json; charset=utf-8;", forHTTPHeaderField: "Content-Type")
		httpRequest.addValue("application/json", forHTTPHeaderField: "Accept")


		var invokeResult: Any?
		var invokeError: CloudError?

		let semaphore = DispatchSemaphore(value: 0)

		let task = urlSession.dataTask(with: httpRequest as URLRequest, completionHandler: {
			httpResponseData, httpResponse, httpResponseError in

			if httpResponseData != nil {
				do {
					let responseDict = try JSONSerialization.jsonObject(with: httpResponseData!, options: []) as! [String:Any]

					if let tracePath = self.debugResponseTracePath {
						try? httpResponseData!.write(to: URL(fileURLWithPath: "\(tracePath)/\(Date()).json"), options: [.atomic])
					}

					if let errorDict = responseDict["error"] as? [String: Any] {
						invokeError = CloudError("", errorDict)
					}
					else if let result = responseDict["result"] {
						invokeResult = result
					}
					else {
						invokeError = CloudError("Response does not conforms to json rpc protocol", nil)
					}
				} catch let error as Any {
					invokeError = CloudError("\(error)", error)
				} catch {
					invokeError = CloudError("unknown error", nil)
				}
			}
			else {
				invokeError = CloudError("HTTP Error: \(httpResponseError)", nil)
			}
			semaphore.signal()
		}) 
		task.resume()
		semaphore.wait(timeout: DispatchTime.distantFuture)


		if invokeError != nil {
			throw invokeError! as! Error
		}
		return invokeResult!
	}

	// MARK: - Internals

	var baseUrl: URL!
	var sessionCacheLocalPaths = Set<String>()
}


extension DependencyContainer {
	func createDefaultCloudConnector(_ baseUrl: URL) {
		register(CloudConnectorDependency, DefaultCloudConnector(baseUrl: baseUrl))
	}
}




