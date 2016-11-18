//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit





open class PickerElement: ViewElement, PickerElementDelegate {

	open var font: UIFont? {
		didSet {
			if let view = view as? PickerElementView {
				view.font = font
			}
		}
	}

	open var maxLines: Int? {
		didSet {
			if let view = view as? PickerElementView {
				view.maxLines = maxLines
			}
		}
	}

	open var rowHeight: CGFloat? {
		didSet {
			if let view = view as? PickerElementView {
				view.rowHeight = rowHeight
			}
		}
	}

	open var color: UIColor? {
		didSet {
			if let view = view as? PickerElementView {
				view.color = color
			}
		}
	}

	open var sections = [PickerSection]() {
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


	open override var frame: CGRect {
		didSet {
			if let view = view as? PickerElementView {
				view.setNeedsLayout()
			}
		}
	}


	open override func createView() -> UIView {
		let picker = PickerElementView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
		picker.dataSource = picker
		picker.delegate = picker
		return picker
	}


	open override func initializeView() {
		super.initializeView()
		guard let view = view as? PickerElementView else {
			return
		}
		view.pickerDelegate = self
		view.sections = sections
		view.font = font
		view.color = color
		view.maxLines = maxLines
		view.rowHeight = rowHeight
	}


	// MARK: - PickerElementDelegate

	open func pickerItemSelected(_ item: Int, inSection section: Int) {
		let section = sections[section]
		if let action = section.selectAction {
			var value: String
			if let itemValue = section.items[item].value , !itemValue.isEmpty {
				value = itemValue
			}
			else {
				value = String(item)
			}
			fragment?.delegate?.onAction(routing: ActionRouting(action: action, value: value))
		}
	}


}




open class PickerItem {
	let title: String
	let value: String?
	init(title: String, value: String?) {
		self.title = title
		self.value = value
	}
}

open class PickerSection {
	open var selectAction: String?
	open var width: CGFloat?
	open var items = [PickerItem]()

	func applyDeclaration(_ element: DeclarationElement, context: DeclarationContext) throws {
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





open class PickerElementDefinition: ViewElementDefinition {

	open var maxLines: Int?
	open var rowHeight: CGFloat?
	open var font: UIFont?
	open var color: UIColor?
	open var sections = [PickerSection]()



	open override func createElement() -> FragmentElement {
		return PickerElement()
	}


	open override func initialize(_ element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)
		guard let element = element as? PickerElement else {
			return
		}
		element.sections = sections
		element.font = font
		element.color = color
		element.maxLines = maxLines
		element.rowHeight = rowHeight
	}


	open override func applyDeclarationAttribute(_ attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		switch attribute.name {
			case "max-lines":
				maxLines = Int(try context.getFloat(attribute))
			case "row-height":
				rowHeight = try context.getFloat(attribute)
			case "font":
				font = try context.getFont(attribute, defaultFont: font)
			case "color":
				color = try context.getColor(attribute)
			default:
				try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
		}
	}


	open override func applyDeclarationElement(_ element: DeclarationElement, context: DeclarationContext) throws -> Bool {
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
	func pickerItemSelected(_ item: Int, inSection section: Int)
}


open class PickerElementView: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {

	open weak var pickerDelegate: PickerElementDelegate?

	open var maxLines: Int?
	open var rowHeight: CGFloat?
	open var color: UIColor?
	open var font: UIFont?

	open var sections = [PickerSection]() {
		didSet {
			reloadAllComponents()
		}
	}


	// MARK: - UIPickerView DataSource, Delegate

	open func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return sections.count
	}


	open func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return sections[component].items.count
	}


	open func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return sections[component].items[row].title
	}


	open func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
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
		paraStyle.alignment = .center
		attributes[NSParagraphStyleAttributeName] = paraStyle
		label!.attributedText = NSAttributedString(string: sections[component].items[row].title, attributes: attributes)
		label!.numberOfLines = maxLines ?? 1
		label!.lineBreakMode = .byTruncatingTail
		return label!
	}



	open func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
		if let width = sections[component].width {
			return width
		}
		return bounds.width
	}


	open func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
		return rowHeight ?? 20
	}


	open func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		pickerDelegate?.pickerItemSelected(row, inSection: component)
	}

}


