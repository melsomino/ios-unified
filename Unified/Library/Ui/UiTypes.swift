//
// Created by Michael Vlasov on 16.07.16.
//

import Foundation
import UIKit



public enum UiAlignment {
	case Fill, Leading, Tailing, Center
}





public struct UiFloatRangeConstraint {
	public var min: CGFloat?
	public var max: CGFloat?
}





public struct UiSizeRangeConstraint {
	public var width: UiFloatRangeConstraint
	public var height: UiFloatRangeConstraint
}





public struct UiFloatRange {
	var min: CGFloat
	var max: CGFloat

	public static func fromValue(value: CGFloat) -> UiFloatRange {
		return UiFloatRange(min: value, max: value)
	}

	public static let zero = UiFloatRange.fromValue(0)
}





public struct UiSizeRange {
	public var width: UiFloatRange
	public var height: UiFloatRange

	public static func fromSize(size: CGSize) -> UiSizeRange {
		return UiSizeRange(width: UiFloatRange.fromValue(size.width), height: UiFloatRange.fromValue(size.height))
	}

	public static let zero = UiSizeRange.fromSize(CGSizeZero)
}



