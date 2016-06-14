//
// Created by Власов М.Ю. on 01.06.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import UIKit

class LayoutText: LayoutViewItem {
	var maxLines: Int {
		didSet {
			label?.numberOfLines = maxLines
		}
	}
	let nowrap: Bool
	let font: UIFont

	var autoHideEmptyText = true

	var text: String? {
		didSet {
			label?.text = text
			if autoHideEmptyText {
				hidden = text == nil || text!.isEmpty
			}
		}
	}

	override var boundView: UIView? {
		return label
	}

	var label: UILabel! {
		didSet {
			if let label = label {
				label.font = font
				label.numberOfLines = maxLines
				label.lineBreakMode = nowrap ? .ByClipping : .ByTruncatingTail
			}
		}
	}





	init(font: UIFont, maxLines: Int = 0, nowrap: Bool = false) {
		self.font = font
		self.maxLines = maxLines
		self.nowrap = nowrap
	}


	// MARK: - LayoutItem


	override func createViews(inSuperview superview: UIView) {
		if label == nil {
			label = UILabel()
			superview.addSubview(label)
		}
	}



	override var visible: Bool {
		return !hidden && text != nil && !text!.isEmpty
	}


	override var fixedSize: Bool {
		return nowrap
	}


	override func measureMaxSize(bounds: CGSize) -> CGSize {
		guard visible else {
			return CGSizeZero
		}
		let measuredText = textForMeasure
		if nowrap {
			return measureText(measuredText, CGFloat.max)
		}
		if maxLines > 0 {
			let singleLine = measuredText.stringByReplacingOccurrencesOfString("\r", withString: "").stringByReplacingOccurrencesOfString("\n", withString: "")
			let singleLineHeight = measureText(singleLine, CGFloat.max).height + 1
			var maxSize = measureText(measuredText, bounds.width)
			let maxHeight = singleLineHeight * CGFloat(maxLines)
			if maxSize.height > maxHeight {
				maxSize.height = maxHeight
			}
			return maxSize
		}
		return measureText(measuredText, bounds.width)
	}





	override func measureSize(bounds: CGSize) -> CGSize {
		guard visible else {
			return CGSizeZero
		}
		let measuredText = textForMeasure
		if nowrap {
			return measureText(measuredText, CGFloat.max)
		}
		if maxLines > 0 {
			let singleLine = measuredText.stringByReplacingOccurrencesOfString("\r", withString: "").stringByReplacingOccurrencesOfString("\n", withString: "")
			let singleLineHeight = measureText(singleLine, CGFloat.max).height + 1
			var size = measureText(measuredText, bounds.width)
			let maxHeight = singleLineHeight * CGFloat(maxLines)
			if size.height > maxHeight {
				size.height = maxHeight
			}
			return size
		}
		return measureText(measuredText, bounds.width)
	}





	// MARK: - Internals


	private var textForMeasure: String {
		return text ?? ""
	}




	private func measureText(text: String, _ width: CGFloat) -> CGSize {
		let constraintSize = CGSize(width: width, height: CGFloat.max)
		let size = text.boundingRectWithSize(constraintSize,
			options: NSStringDrawingOptions.UsesLineFragmentOrigin,
			attributes: [NSFontAttributeName: font],
			context: nil).size
		return size
	}


}



