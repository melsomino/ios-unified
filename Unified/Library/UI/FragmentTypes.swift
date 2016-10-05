//
// Created by Michael Vlasov on 16.07.16.
//

import Foundation
import UIKit





public struct SizeMeasure {
	public var width: (min:CGFloat, max:CGFloat) = (0, 0)
	public var height: CGFloat = 0

	public init(width: (CGFloat, CGFloat), height: CGFloat) {
		self.width = width
		self.height = height
	}

	public init(width: CGFloat, height: CGFloat) {
		self.width = (width, width)
		self.height = height
	}

	public init(size: CGSize) {
		self.width = (size.width, size.width)
		self.height = size.height
	}

	public var maxSize: CGSize {
		return CGSize(width: width.max, height: height)
	}

	public static let zero = SizeMeasure(width: 0, height: 0)
}





public enum FragmentAlignment {
	case leading, center, tailing, fill


	public static func alignedFrame(ofSize size: CGSize, inBounds bounds: CGRect, horizontalAlignment: FragmentAlignment, verticalAlignment: FragmentAlignment) -> CGRect {
		let (x, width) = horizontalAlignment.calc_frame(size.width, bounds.origin.x, bounds.width)
		let (y, height) = verticalAlignment.calc_frame(size.height, bounds.origin.y, bounds.height)
		return CGRect(x: x, y: y, width: width, height: height)
	}


	public static let names = [
		"fill": FragmentAlignment.fill,
		"leading": FragmentAlignment.leading,
		"tailing": FragmentAlignment.tailing,
		"center": FragmentAlignment.center
	]


	public static let horizontal_names = [
		"fill": FragmentAlignment.fill,
		"leading": FragmentAlignment.leading,
		"tailing": FragmentAlignment.tailing,
		"center": FragmentAlignment.center,
		"left": FragmentAlignment.leading,
		"right": FragmentAlignment.tailing,
	]


	public static let vertical_names = [
		"fill": FragmentAlignment.fill,
		"leading": FragmentAlignment.leading,
		"tailing": FragmentAlignment.tailing,
		"center": FragmentAlignment.center,
		"top": FragmentAlignment.leading,
		"bottom": FragmentAlignment.tailing
	]

	// MARK: - Internals

	fileprivate func calc_frame(_ size: CGFloat, _ bounds_origin: CGFloat, _ bounds_size: CGFloat) -> (CGFloat, CGFloat) {
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

