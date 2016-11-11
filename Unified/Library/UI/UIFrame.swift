//
// Created by Власов М.Ю. on 11.11.16.
//

import Foundation
import UIKit


private func parse(element: DeclarationElement, startAttribute: Int,
	attributes: [String: (DeclarationAttribute) throws -> Void],
	children: [String: (DeclarationElement) throws -> Void]) throws {
	if attributes.count > 0 {
		for i in startAttribute ..< element.attributes.count {
			let attribute = element.attributes[i]
			if let parser = attributes[attribute.name] {
				try parser(attribute)
			}
		}
	}
	if children.count > 0 {
		for child in element.children {
			if let parser = children[child.name] {
				try parser(child)
			}
		}
	}
}



public class FrameNavigationBarDefinition {
	public final let backgroundColor: UIColor?

	public init(backgroundColor: UIColor?) {
		self.backgroundColor = backgroundColor
	}



	public static func from(element: DeclarationElement, context: DeclarationContext) throws -> FrameNavigationBarDefinition {
		var backgroundColor: UIColor?
		try parse(element: element, startAttribute: 0, attributes: [
			"background-color": {
				backgroundColor = try context.getColor($0)
			}
		], children: [:])
		return FrameNavigationBarDefinition(backgroundColor: backgroundColor)
	}



	public final func apply(controller: UIViewController) {
//		let navigation = controller.navigationItem
		if let bar: UINavigationBar = controller.navigationController?.navigationBar {
			bar.backgroundColor = backgroundColor
		}
	}

	public static let zero = FrameNavigationBarDefinition(backgroundColor: nil)
}



public class FrameDefinition {
	public final let navigationBar: FrameNavigationBarDefinition
	public final let backgroundColor: UIColor

	init(backgroundColor: UIColor, navigationBar: FrameNavigationBarDefinition) {
		self.backgroundColor = backgroundColor
		self.navigationBar = navigationBar
	}



	public static func from(element: DeclarationElement, startAttribute: Int, context: DeclarationContext) throws -> FrameDefinition {
		var navigationBar = FrameNavigationBarDefinition.zero
		var backgroundColor = UIColor.clear
		try parse(element: element, startAttribute: startAttribute,
			attributes: [
				"background-color": {
					backgroundColor = try context.getColor($0)
				}
			],
			children: [
				"navigation-bar": {
					navigationBar = try FrameNavigationBarDefinition.from(element: $0, context: context)
				}
			]
		)
		return FrameDefinition(backgroundColor: backgroundColor, navigationBar: navigationBar)
	}



	static func setup() {
		DefaultRepository.register(section: "ui-frame") {
			element, startAttribute, context in
			return (element.attributes[startAttribute].name, try FrameDefinition.from(element: element, startAttribute: startAttribute, context: context))
		}
	}
}



