//
// Created by Власов М.Ю. on 16.11.16.
//

import Foundation
import UIKit


public class FrameNavigationBarDefinition {
	final let barTintColor: UIColor?
	final let tintColor: UIColor?
	final let translucent: Bool
	final let title: FrameBarTitle
	final let left: [FrameBarItem]
	final let right: [FrameBarItem]

	init(barTintColor: UIColor?, tintColor: UIColor?, translucent: Bool,
		title: FrameBarTitle, left: [FrameBarItem], right: [FrameBarItem]) {
		self.barTintColor = barTintColor
		self.tintColor = tintColor
		self.translucent = translucent
		self.title = title
		self.left = left
		self.right = right
	}



	static func items(from element: DeclarationElement, context: DeclarationContext) throws -> [FrameBarItem] {
		var items = [FrameBarItem]()
		for child in element.children {
			items.append(try FrameBarItem.from(element: child, context: context))
		}
		return items
	}



	public static func from(element: DeclarationElement, context: DeclarationContext) throws -> FrameNavigationBarDefinition {
		var barTintColor: UIColor?
		var tintColor: UIColor?
		var translucent = true
		var title: FrameBarTitle = FrameBarTitleText.zero
		var left = [FrameBarItem]()
		var right = [FrameBarItem]()
		try parse(element: element, startAttribute: 0, attributes: [
			"bar-tint-color": {
				barTintColor = try context.getColor($0)
			},
			"tint-color": {
				tintColor = try context.getColor($0)
			},
			"translucent": {
				translucent = try context.getBool($0)
			}
		], children: [
			"title": {
				title = try FrameBarTitle.from(element: $0, context: context)
			},
			"left": {
				left = try items(from: $0, context: context)
			},
			"right": {
				right = try items(from: $0, context: context)
			}
		])
		return FrameNavigationBarDefinition(barTintColor: barTintColor, tintColor: tintColor, translucent: translucent,
			title: title, left: left, right: right.reversed())
	}



	final func apply(frame: FrameBuilder) throws {
		if let bar = frame.bar {
			bar.barTintColor = barTintColor
			bar.tintColor = tintColor
			bar.isTranslucent = translucent
			try title.apply(frame: frame)
		}
		var items = [UIBarButtonItem]()
		for factory in left {
			items.append(factory.create(frame: frame))
		}
		frame.navigation.setLeftBarButtonItems(items, animated: false)
		items.removeAll()
		for factory in right {
			items.append(factory.create(frame: frame))
		}
		frame.navigation.setRightBarButtonItems(items, animated: false)
	}

	public static let zero = FrameNavigationBarDefinition(barTintColor: nil, tintColor: nil, translucent: true,
		title: FrameBarTitleText.zero, left: [], right: [])
}


