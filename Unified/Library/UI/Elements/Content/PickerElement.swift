//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit





public class PickerElement: ViewElement, PickerElementDelegate {

	public var font: UIFont? {
		didSet {
			if let view = view as? PickerElementView {
				view.font = font
			}
		}
	}

	public var color: UIColor? {
		didSet {
			if let view = view as? PickerElementView {
				view.color = color
			}
		}
	}

	public var sections = [PickerSection]() {
		didSet {
			if let view = view as? PickerElementView {
				view.sections = sections
			}
		}
	}

	public init() {
		super.init(nil)
	}


	// MARK: - LayoutItem


	public override var frame: CGRect {
		didSet {
			if let view = view as? PickerElementView {
				view.setNeedsLayout()
			}
		}
	}


	public override func createView() -> UIView {
		let picker = PickerElementView(frame: CGRectMake(0, 0, 100, 100))
		picker.dataSource = picker
		picker.delegate = picker
		return picker
	}


	public override func initializeView() {
		super.initializeView()
		guard let view = view as? PickerElementView else {
			return
		}
		view.pickerDelegate = self
		view.sections = sections
		view.font = font
		view.color = color
	}


	// MARK: - PickerElementDelegate

	public func pickerItemSelected(item: Int, inSection section: Int) {
		let section = sections[section]
		if let action = section.selectAction {
			var actionWithArgs = ""
			if let value = section.items[item].value where !value.isEmpty {
				actionWithArgs = "\(action) \(value)"
			}
			else {
				actionWithArgs = "\(action) \(item)"
			}
			delegate?.tryExecuteAction(DynamicBindings.Literal(value: actionWithArgs, next: nil))
		}
	}


}




public class PickerItem {
	let title: String
	let value: String?
	init(title: String, value: String?) {
		self.title = title
		self.value = value
	}
}

public class PickerSection {
	public var selectAction: String?
	public var width: CGFloat?
	public var items = [PickerItem]()

	func applyDeclaration(element: DeclarationElement, context: DeclarationContext) throws {
		for attribute in element.attributes {
			switch attribute.name {
				case "select-action":
					selectAction = try context.getString(attribute)
				case "width":
					width = try context.getFloat(attribute)
				default:
					break
			}
		}
		items.reserveCapacity(element.children.count)
		for child in element.children {
			items.append(PickerItem(title: child.name, value: child.value))
		}
	}
}





public class PickerElementDefinition: ViewElementDefinition {

	public var font: UIFont?
	public var color: UIColor?
	public var sections = [PickerSection]()



	public override func createElement() -> FragmentElement {
		return PickerElement()
	}


	public override func initialize(element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)
		guard let element = element as? PickerElement else {
			return
		}
		element.sections = sections
		element.font = font
		element.color = color
	}


	public override func applyDeclarationAttribute(attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		switch attribute.name {
			case "font":
				font = try context.getFont(attribute, defaultFont: font)
			case "color":
				color = try context.getColor(attribute)
			default:
				try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
		}
	}


	public override func applyDeclarationElement(element: DeclarationElement, context: DeclarationContext) throws -> Bool {
		switch element.name {
			case "section":
				let section = PickerSection()
				try section.applyDeclaration(element, context: context)
				sections.append(section)
				return true
			default:
				return try super.applyDeclarationElement(element, context: context)
		}
	}

}



public protocol PickerElementDelegate: class {
	func pickerItemSelected(item: Int, inSection section: Int)
}


public class PickerElementView: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {

	public weak var pickerDelegate: PickerElementDelegate?

	public var color: UIColor?
	public var font: UIFont?

	public var sections = [PickerSection]() {
		didSet {
			reloadAllComponents()
		}
	}


	// MARK: - UIPickerView DataSource, Delegate

	public func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
		return sections.count
	}


	public func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return sections[component].items.count
	}


	public func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return sections[component].items[row].title
	}


	public func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
		var label = view as? UILabel
		if label == nil {
			label = UILabel()
//			label!.textAlignment = .Center
//			if let font = font {
//				label!.font = font
//			}
//			if let color = color {
//				label!.textColor = color
//			}
		}
		var attributes = [String: AnyObject]()
		if let font = font {
			attributes[NSFontAttributeName] = font
		}
		if let color = color {
			attributes[NSForegroundColorAttributeName] = color
		}
		let paraStyle = NSMutableParagraphStyle()
		paraStyle.paragraphSpacing = 0
		paraStyle.paragraphSpacingBefore = 0
		paraStyle.paragraphSpacingBefore = 0
		let horPadding = CGFloat(8)
		paraStyle.firstLineHeadIndent = horPadding
		paraStyle.headIndent = horPadding
		paraStyle.tailIndent = -horPadding
		paraStyle.alignment = .Center
		paraStyle.lineBreakMode = .ByTruncatingTail
		attributes[NSParagraphStyleAttributeName] = paraStyle
		label!.numberOfLines = 1
		label!.lineBreakMode = .ByTruncatingTail

		label!.attributedText = NSAttributedString(string: sections[component].items[row].title, attributes: attributes)
		return label!
	}



	public func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
		if let width = sections[component].width {
			return width
		}
		return bounds.width
	}


	public func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		pickerDelegate?.pickerItemSelected(row, inSection: component)
	}

}


