//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class LayoutLabel: LayoutViewItem {

	public var maxLines = 0 {
		didSet {
			initializeView()
		}
	}

	public var nowrap = false

	public var font: UIFont? {
		didSet {
			initializeView()
		}
	}

	public var color: UIColor? {
		didSet {
			initializeView()
		}
	}

	public var autoHideEmptyText = true

	public var text: String? {
		didSet {
			if let label = view as? UILabel {
				label.text = text
			}
			if autoHideEmptyText {
				hidden = text == nil || text!.isEmpty
			}
		}
	}


	public override required init() {
		super.init()
	}

	// MARK: - LayoutViewItem


	public override func initializeView() {
		super.initializeView()
		if let label = view as? UILabel {
			label.font = resolveFont()
			if let color = color {
				label.textColor = color
			}
			else {
				label.textColor = UIColor.blackColor()
			}

			label.numberOfLines = maxLines
			label.lineBreakMode = nowrap ? .ByClipping : .ByTruncatingTail
		}
	}


	// MARK: - LayoutItem


	public override func createView() -> UIView {
		return UILabel()
	}



	public override var visible: Bool {
		return !hidden && text != nil && !text!.isEmpty
	}


	public override var fixedSize: Bool {
		return nowrap
	}


	public override func measureMaxSize(bounds: CGSize) -> CGSize {
		guard visible else {
			return CGSizeZero
		}
		let measuredText = textForMeasure()
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





	public override func measureSize(bounds: CGSize) -> CGSize {
		guard visible else {
			return CGSizeZero
		}
		let measuredText = textForMeasure()
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


	private func textForMeasure() -> String {
		return text ?? ""
	}




	private func measureText(text: String, _ width: CGFloat) -> CGSize {
		let constraintSize = CGSize(width: width, height: CGFloat.max)
		let size = text.boundingRectWithSize(constraintSize,
			options: NSStringDrawingOptions.UsesLineFragmentOrigin,
			attributes: [NSFontAttributeName: resolveFont()],
			context: nil).size
		return size
	}


	private func resolveFont() -> UIFont {
		return font ?? UIFont.systemFontOfSize(UIFont.systemFontSize())
	}
}



