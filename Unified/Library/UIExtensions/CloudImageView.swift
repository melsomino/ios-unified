//
// Created by Michael Vlasov on 25.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

open class CloudImageView: UIImageView, CloudFileListener {

	open var imageSize: CGSize?

	open var placeholder: UIImage?
	open var imageFile: CloudFile! {
		didSet {
			oldValue?.removeListener(self)
			imageFile?.addListener(self)
			reflectImageState(animated: false)
		}
	}


	// MARK: - CloudFileListener


	open func cloudFileStateChanged(_ file: CloudFile) {
		weak var weakSelf = self
		OperationQueue.main.addOperation {
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


	private var currentState = CloudFileState.loading(0)
	private var pendingImageFilePath = ""


	deinit {
		imageFile?.removeListener(self)
	}





	private func reflectImageState(animated: Bool) {
		let state = imageFile?.state ?? .loading(0)
		switch state {
			case .loaded:
				startLoadImage(imageFile.localPath)
			case .loading:
				image = placeholder
			case .failed:
				image = placeholder
		}
		currentState = state
	}




	private func startLoadImage(_ imageFilePath: String) {
		pendingImageFilePath = imageFilePath
		let bounds = imageSize ?? self.bounds.size
		weak var weakSelf = self
		OperationQueue().addOperation {
			guard let strongSelf = weakSelf else {
				return
			}
			guard strongSelf.pendingImageFilePath == imageFilePath else {
				return
			}
			guard let imageData = try? Data(contentsOf: URL(fileURLWithPath: imageFilePath)) else {
				return
			}
			guard let image = UIImage(data: imageData) else {
				return
			}
			let ratio = max(bounds.width / image.size.width, bounds.height / image.size.height)
			let thumbnailSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)

			UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, UIScreen.main.scale);
			image.draw(in: CGRect(x: 0, y: 0, width: thumbnailSize.width, height: thumbnailSize.height))
			let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()

			OperationQueue.main.addOperation {
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
