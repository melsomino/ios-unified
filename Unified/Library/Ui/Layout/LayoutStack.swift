//
// Created by Власов М.Ю. on 01.06.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import UIKit

public enum LayoutStackDirection {
	case Horizontal, Vertical
}




private struct StackPosition {
	var along: CGFloat = 0
	var across: CGFloat = 0

	init() {

	}

	init(_ along: CGFloat, _ across: CGFloat) {
		self.along = along
		self.across = across
	}

	init(_ size: CGSize, _ horizontal: Bool) {
		self.along = horizontal ? size.width : size.height
		self.across = horizontal ? size.height : size.width
	}

	init(_ point: CGPoint, _ horizontal: Bool) {
		self.along = horizontal ? point.x : point.y
		self.across = horizontal ? point.y : point.x
	}

	mutating func clear() {
		along = 0
		across = 0
	}
	func toSize(horizontal: Bool) -> CGSize {
		return CGSizeMake(horizontal ? along : across, horizontal ? across : along)
	}

	func toPoint(horizontal: Bool) -> CGPoint {
		return CGPointMake(horizontal ? along : across, horizontal ? across : along)
	}

}


private struct Measured {
	var content: LayoutItem!
	var maxSize = StackPosition()
	var size = StackPosition()

	init() {
	}

	mutating func measureMaxSize(content: LayoutItem, _ bounds: StackPosition, _ horizontal: Bool) -> StackPosition {
		self.content = content
		let contentMaxSize = content.measureMaxSize(bounds.toSize(horizontal))
		maxSize = StackPosition(contentMaxSize, horizontal)
		return maxSize
	}

	mutating func measureSize(bounds: StackPosition, _ horizontal: Bool) -> StackPosition {
		size = StackPosition(content.measureSize(bounds.toSize(horizontal)), horizontal)
		return size
	}
}



public class LayoutStack: LayoutItem {

	let direction: LayoutStackDirection
	let along: LayoutAlignment
	let across: LayoutAlignment
	let spacing: CGFloat
	let content: [LayoutItem]

	private var measured = [Measured]()
	private var measuredCount = 0
	private var maxSize = StackPosition()
	private var fixedSpace: CGFloat = 0
	private var notFixedMaxSpace: CGFloat = 0
	private var spacingSize: CGFloat = 0
	private var size = StackPosition()


	init(direction: LayoutStackDirection, along: LayoutAlignment, across: LayoutAlignment, spacing: CGFloat, _ content: [LayoutItem]) {
		self.direction = direction
		self.along = along
		self.across = across
		self.spacing = spacing
		self.content = content
	}





	public override var visible: Bool {
		for item in content {
			if item.visible {
				return true
			}
		}
		return false
	}


	public override func createViews(inSuperview superview: UIView) {
		for item in content {
			item.createViews(inSuperview: superview)
		}
	}


	public override func collectFrameItems(inout items: [LayoutFrameItem]) {
		for item in content {
			item.collectFrameItems(&items)
		}
	}


	public override func measureMaxSize(bounds: CGSize) -> CGSize {
		let horizontal = direction == .Horizontal
		let stackBounds = StackPosition(bounds, horizontal)
		measuredCount = 0
		maxSize.clear()
		spacingSize = 0
		fixedSpace = 0
		notFixedMaxSpace = 0
		for item in content {
			if item.visible {
				if measuredCount >= measured.count {
					measured.append(Measured())
				}
				let itemMaxSize = measured[measuredCount].measureMaxSize(item, stackBounds, horizontal)
				measuredCount += 1
				if measuredCount > 1 {
					maxSize.along += spacing
					spacingSize += spacing
				}
				maxSize.along += itemMaxSize.along
				maxSize.across = max(itemMaxSize.across, maxSize.across)
				if item.fixedSize {
					fixedSpace += itemMaxSize.along
				}
				else {
					notFixedMaxSpace += itemMaxSize.along
				}
			}
		}
		return maxSize.toSize(horizontal)
	}





	public override func measureSize(bounds: CGSize) -> CGSize {
		let horizontal = direction == .Horizontal
		let stackBounds = StackPosition(bounds, horizontal)
		size.clear()
		let nonFixedSpace = stackBounds.along - spacingSize - fixedSpace
		for index in 0 ..< measuredCount {
			let item = measured[index]
			var itemBounds = StackPosition()
			itemBounds.across = stackBounds.across
			if item.content.fixedSize || nonFixedSpace <= 0 {
				itemBounds.along = item.maxSize.along
			}
			else {
				itemBounds.along = along == .Fill ? nonFixedSpace * item.maxSize.along / notFixedMaxSpace : min(item.maxSize.along, stackBounds.along)
			}
			var itemSize = measured[index].measureSize(itemBounds, horizontal)
			if along == .Fill && !item.content.fixedSize && itemSize.along < itemBounds.along {
				itemSize.along = itemBounds.along
			}
			measured[index].size = itemSize
			if index > 0 {
				size.along += spacing
			}
			size.along += itemSize.along
			size.across = max(itemSize.across, size.across)

		}
		return size.toSize(horizontal)
	}





	public override func layout(bounds: CGRect) -> CGRect {
		let horizontal = direction == .Horizontal
		var stackOrigin = StackPosition(bounds.origin, horizontal)
		var stackBounds = StackPosition(bounds.size, horizontal)
		if across != .Fill && size.across < stackBounds.across {
			stackBounds.across = size.across
		}
		for index in 0 ..< measuredCount {
			let item = measured[index]
			var itemOrigin = stackOrigin
			var itemSize = item.size

			switch across {
				case .Tailing:
					itemOrigin.across = stackOrigin.across + stackBounds.across - itemSize.across
				case .Center:
					itemOrigin.across = stackOrigin.across + stackBounds.across / 2 - itemSize.across / 2
				default:
					itemSize.across = stackBounds.across
			}

			item.content.layout(CGRect(origin: itemOrigin.toPoint(horizontal), size: itemSize.toSize(horizontal)))

			stackOrigin.along += itemSize.along + spacing
		}

		return CGRect(origin:  bounds.origin, size: size.toSize(horizontal))
	}

}

