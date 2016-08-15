//
// Created by Michael Vlasov on 12.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation


public class DefaultCloudConnector: CloudConnector {

	public var debugResponseTracePath: String?

	public init(baseUrl: NSURL) {
		self.baseUrl = baseUrl
	}


	// MARK: - CloudConnector

	var urlSession: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())


	public func getFileCache(localPath: String) -> CloudFileCache {
		if !sessionCacheLocalPaths.contains(localPath) {
			let fm = NSFileManager.defaultManager()
			do {
				for file in try fm.contentsOfDirectoryAtPath(localPath) {
					let _ = try? fm.removeItemAtPath(localPath + "/" + file)
				}
			}
			catch {
			}
			sessionCacheLocalPaths.insert(localPath)
		}
		return DefaultCloudFilesCache(cloudConnector: self, localPath: localPath)
	}


	public func makeUrl(relativePath: String) -> NSURL {
		return NSURL(string: relativePath, relativeToURL: baseUrl)!
	}

	public func startDownload(request: NSURLRequest, progress: ((Int64, Int64) -> Void)?, error: ((ErrorType) -> Void)?, complete: (NSURL) -> Void) {
		let task = urlSession.downloadTaskWithRequest(request) {
			downloadedUrl, httpResponse, httpResponseError in
			if httpResponseError != nil {
				if let onError = error {
					onError(httpResponseError!)
				}
				return
			}
			if downloadedUrl == nil {
				if let onError = error {
					onError(CloudError("Ошибка загрузки файла", nil))
				}
				return
			}
			complete(downloadedUrl!)
		}
		task.resume()
	}

	public func invokeService(serviceUrl: NSURL, _ protocolVersion: Int, _ method: String, _ params: AnyObject) throws -> AnyObject {
		var json = [String: AnyObject]()

		json["jsonrpc"] = "2.0"
		json["protocol"] = protocolVersion
		json["method"] = method
		json["params"] = params

		let httpRequest = NSMutableURLRequest(URL: serviceUrl, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 60.0)
		let httpRequestJson = ["jsonrpc": "2.0", "protocol": protocolVersion, "method": method, "params": params]
		let httpRequestData = try! NSJSONSerialization.dataWithJSONObject(httpRequestJson, options: [])

		httpRequest.HTTPMethod = "POST"
		httpRequest.HTTPBody = httpRequestData
		httpRequest.addValue("application/json; charset=utf-8;", forHTTPHeaderField: "Content-Type")
		httpRequest.addValue("application/json", forHTTPHeaderField: "Accept")


		var invokeResult: AnyObject?
		var invokeError: CloudError?

		let semaphore = dispatch_semaphore_create(0)

		let task = urlSession.dataTaskWithRequest(httpRequest) {
			httpResponseData, httpResponse, httpResponseError in

			if httpResponseData != nil {
				do {
					let responseDict = try NSJSONSerialization.JSONObjectWithData(httpResponseData!, options: []) as! [String:AnyObject]

					if let tracePath = self.debugResponseTracePath {
						httpResponseData!.writeToFile("\(tracePath)/\(NSDate()).json", atomically: true)
					}

					if let errorDict = responseDict["error"] as? [String: AnyObject] {
						invokeError = CloudError("", errorDict)
					}
					else if let result = responseDict["result"] {
						invokeResult = result
					}
					else {
						invokeError = CloudError("Response does not conforms to json rpc protocol", nil)
					}
				} catch let error as AnyObject {
					invokeError = CloudError("\(error)", error)
				} catch {
					invokeError = CloudError("unknown error", nil)
				}
			}
			else {
				invokeError = CloudError("HTTP Error: \(httpResponseError)", nil)
			}
			dispatch_semaphore_signal(semaphore)
		}
		task.resume()
		dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)


		if invokeError != nil {
			throw invokeError!
		}
		return invokeResult!
	}

	// MARK: - Internals

	var baseUrl: NSURL!
	var sessionCacheLocalPaths = Set<String>()
}


extension DependencyContainer {
	func createDefaultCloudConnector(baseUrl: NSURL) {
		register(CloudConnectorDependency, DefaultCloudConnector(baseUrl: baseUrl))
	}
}




