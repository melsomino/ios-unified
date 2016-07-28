//
// Created by Michael Vlasov on 16.07.16.
//

import Foundation
import UIKit



public enum UiAlignment {
	case leading, center, tailing, fill


	public static func alignedFrame(ofSize size: CGSize, inBounds bounds: CGRect, horizontalAlignment: UiAlignment, verticalAlignment: UiAlignment) -> CGRect {
		let (x, width) = horizontalAlignment.calc_frame(size.width, bounds.origin.x, bounds.width)
		let (y, height) = verticalAlignment.calc_frame(size.height, bounds.origin.y, bounds.height)
		return CGRectMake(x, y, width, height)
	}


	public static let names = [
		"fill": UiAlignment.fill,
		"leading": UiAlignment.leading,
		"tailing": UiAlignment.tailing,
		"center": UiAlignment.center
	]


	public static let horizontal_names = [
		"fill": UiAlignment.fill,
		"leading": UiAlignment.leading,
		"tailing": UiAlignment.tailing,
		"center": UiAlignment.center,
		"left": UiAlignment.leading,
		"right": UiAlignment.tailing,
	]


	public static let vertical_names = [
		"fill": UiAlignment.fill,
		"leading": UiAlignment.leading,
		"tailing": UiAlignment.tailing,
		"center": UiAlignment.center,
		"top": UiAlignment.leading,
		"bottom": UiAlignment.tailing
	]

	// MARK: - Internals

	private func calc_frame(size: CGFloat, _ bounds_origin: CGFloat, _ bounds_size: CGFloat) -> (CGFloat, CGFloat) {
		switch self {
			case .leading:
				return (bounds_origin, size)
			case .center:
				return (bounds_origin + bounds_size / 2 - size / 2, size)
			case .tailing:
				return (bounds_origin + bounds_size - size, size)
			case .fill:
				return (bounds_origin, bounds_size)
		}
	}

}

