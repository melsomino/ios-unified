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
	public final let barTintColor: UIColor?
	public final let tintColor: UIColor?
	public final let translucent: Bool
	public final let title: DynamicBindings.Expression

	public init(barTintColor: UIColor?, tintColor: UIColor?, translucent: Bool,
		title: DynamicBindings.Expression) {
		self.barTintColor = barTintColor
		self.tintColor = tintColor
		self.translucent = translucent
		self.title = title
	}



	public static func from(element: DeclarationElement, context: DeclarationContext) throws -> FrameNavigationBarDefinition {
		var barTintColor: UIColor?
		var tintColor: UIColor?
		var translucent = true
		var title: DynamicBindings.Expression = DynamicBindings.zeroExpression
		try parse(element: element, startAttribute: 0, attributes: [
			"bar-tint-color": {
				barTintColor = try context.getColor($0)
			},
			"tint-color": {
				tintColor = try context.getColor($0)
			},
			"translucent": {
				translucent = try context.getBool($0)
			},
			"title": {
				title = try context.getExpression($0) ?? title
			}
		], children: [:])
		return FrameNavigationBarDefinition(barTintColor: barTintColor, tintColor: tintColor, translucent: translucent, title: title)
	}



	final func apply(values: [Any?], controller: UIViewController) {
		if let bar: UINavigationBar = controller.navigationController?.navigationBar {
			bar.barTintColor = barTintColor
			bar.tintColor = tintColor
			bar.isTranslucent = translucent
		}
		let navigation = controller.navigationItem
		navigation.title = title.evaluate(values)
	}

	public static let zero = FrameNavigationBarDefinition(barTintColor: nil, tintColor: nil, translucent: true, title: DynamicBindings.zeroExpression)
}



public class FrameDefinition {
	public static let zero = FrameDefinition(bindings: DynamicBindings(), backgroundColor: .white, navigationBar: FrameNavigationBarDefinition.zero)

	public static let RepositorySection = "ui-frame"

	public final let bindings: DynamicBindings
	public final let navigationBar: FrameNavigationBarDefinition
	public final let backgroundColor: UIColor

	init(bindings: DynamicBindings, backgroundColor: UIColor, navigationBar: FrameNavigationBarDefinition) {
		self.bindings = bindings
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
		return FrameDefinition(bindings: context.bindings, backgroundColor: backgroundColor, navigationBar: navigationBar)
	}

	final func apply(model: AnyObject, controller: UIViewController) {
		var values = [Any?](repeating: nil, count: bindings.valueIndexByName.count)
		let mirror = Mirror(reflecting: model)
		for member in mirror.children {
			if let name = member.label {
				if let index = bindings.valueIndexByName[name] {
					values[index] = member.value
				}
			}
		}
		navigationBar.apply(values: values, controller: controller)
	}


	static func setup() {
		DefaultRepository.register(section: RepositorySection) {
			element, startAttribute, context in
			return (element.attributes[startAttribute].name, try FrameDefinition.from(element: element, startAttribute: startAttribute, context: context))
		}
	}
}



