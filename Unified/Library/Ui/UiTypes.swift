//
// Created by Michael Vlasov on 16.07.16.
//

import Foundation
import UIKit





public enum UiAlignment {
	case Leading, Center, Tailing, Fill


	public static func calcFrame(ofSize size: CGSize, inBounds bounds: CGRect, horizontalAlignment: UiAlignment, verticalAlignment: UiAlignment) -> CGRect {
		let (x, width) = horizontalAlignment.calc_frame(size.width, bounds.origin.x, bounds.width)
		let (y, height) = verticalAlignment.calc_frame(size.height, bounds.origin.y, bounds.height)
		return CGRectMake(x, y, width, height)
	}


	public static let names = [
		"fill": UiAlignment.Fill,
		"leading": UiAlignment.Leading,
		"tailing": UiAlignment.Tailing,
		"center": UiAlignment.Center
	]


	public static let horizontal_names = [
		"fill": UiAlignment.Fill,
		"leading": UiAlignment.Leading,
		"tailing": UiAlignment.Tailing,
		"center": UiAlignment.Center,
		"left": UiAlignment.Leading,
		"right": UiAlignment.Tailing,
	]


	public static let vertical_names = [
		"fill": UiAlignment.Fill,
		"leading": UiAlignment.Leading,
		"tailing": UiAlignment.Tailing,
		"center": UiAlignment.Center,
		"top": UiAlignment.Leading,
		"bottom": UiAlignment.Tailing
	]

	// MARK: - Internals

	private func calc_frame(size: CGFloat, _ bounds_origin: CGFloat, _ bounds_size: CGFloat) -> (CGFloat, CGFloat) {
		switch self {
			case .Leading:
				return (bounds_origin, size)
			case .Center:
				return (bounds_origin + bounds_size / 2 - size / 2, size)
			case .Tailing:
				return (bounds_origin + bounds_size - size, size)
			case .Fill:
				return (bounds_origin, bounds_size)
		}
	}

}

