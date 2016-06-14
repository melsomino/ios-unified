//
// Created by Власов М.Ю. on 25.05.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import UIKit

public class CloudImageView: UIImageView, CloudFileListener {


	public var imageFile: CloudFile! {
		didSet {
			oldValue?.removeListener(self)
			imageFile?.addListener(self)
			reflectImageState(animated: false)
		}
	}


	// MARK: - CloudFileListener


	public func cloudFileStateChanged(file: CloudFile) {
		weak var weakSelf = self
		NSOperationQueue.mainQueue().addOperationWithBlock {
			guard let strongSelf = weakSelf else {
				return
			}
			guard file.localPath == strongSelf.imageFile?.localPath else {
				return
			}
			strongSelf.reflectImageState(animated: true)
		}
	}



	// MARK: - Internals


	private var currentState = CloudFileState.Loading
	private var pendingImageFilePath = ""


	deinit {
		imageFile?.removeListener(self)
	}





	private func reflectImageState(animated animated: Bool) {
		let state = imageFile?.state ?? .Loading
		switch state {
			case .Loaded:
				startLoadImage(imageFile.localPath)
			case .Loading:
				image = UIImage(named: "NotificationsImagePlaceholder")
			case .Failed:
				image = UIImage(named: "NotificationsImagePlaceholder")
		}
		currentState = state
	}




	private func startLoadImage(imageFilePath: String) {
		pendingImageFilePath = imageFilePath
		let bounds = self.bounds.size
		weak var weakSelf = self
		NSOperationQueue().addOperationWithBlock {
			guard let strongSelf = weakSelf else {
				return
			}
			guard strongSelf.pendingImageFilePath == imageFilePath else {
				return
			}
			guard let imageData = NSData(contentsOfFile: imageFilePath) else {
				return
			}
			guard let image = UIImage(data: imageData) else {
				return
			}
			let ratio = max(bounds.width / image.size.width, bounds.height / image.size.height)
			let thumbnailSize = CGSizeMake(image.size.width * ratio, image.size.height * ratio)

			UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, UIScreen.mainScreen().scale);
			image.drawInRect(CGRectMake(0, 0, thumbnailSize.width, thumbnailSize.height))
			let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()

			NSOperationQueue.mainQueue().addOperationWithBlock {
				guard let strongSelf = weakSelf else {
					return
				}
				guard strongSelf.pendingImageFilePath == imageFilePath else {
					return
				}
				strongSelf.image = thumbnail
			}
		}
	}
}
