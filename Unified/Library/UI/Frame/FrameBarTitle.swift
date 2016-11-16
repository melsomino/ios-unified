//
// Created by Власов М.Ю. on 16.11.16.
//

import Foundation
import UIKit

class FrameBarTitle {
	func apply(frame: FrameBuilder) {
	}



	static func from(element: DeclarationElement, context: DeclarationContext) throws -> FrameBarTitle {
		var text: DynamicBindings.Expression?
		var textAttributes = [String: Any]()
		var action: DynamicBindings.Expression?
		for attribute in element.attributes[1 ..< element.attributes.count] {
			switch attribute.name {
				case "text":
					guard let expression = try context.getExpression(attribute) else {
						throw DeclarationError("Invalid navigation bar title definition", attribute, context)
					}
					text = expression
				case "font":
					textAttributes[NSFontAttributeName] = try context.getFont(attribute, defaultFont: nil)
				case "color":
					textAttributes[NSForegroundColorAttributeName] = try context.getColor(attribute)
				case "action":
					action = try context.getExpression(attribute)
				default:
					break
			}
		}
		if let text = text {
			return FrameBarTitleText(text: text, attributes: textAttributes, action: action)
		}
		throw DeclarationError("Invalid navigation bar item definition", element, context)
	}
}



class FrameBarTitleText: FrameBarTitle {
	let text: DynamicBindings.Expression
	let attributes: [String: Any]?
	let action: DynamicBindings.Expression?

	init(text: DynamicBindings.Expression, attributes: [String: Any]?, action: DynamicBindings.Expression?) {
		self.text = text
		self.attributes = attributes
		self.action = action
	}



	override func apply(frame: FrameBuilder) {
		guard let action = action else {
			frame.navigation.title = text.evaluate(frame.modelValues)
			frame.bar?.titleTextAttributes = attributes
			return
		}

		let titleAttributes = attributes ?? UINavigationBar.appearance().titleTextAttributes
		let titleString = NSAttributedString(string: text.evaluate(frame.modelValues) ?? "", attributes: titleAttributes)

		let titleView = UILabel()
		titleView.numberOfLines = 2
		titleView.attributedText = titleString
		titleView.textAlignment = .center
		let width = titleView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
		titleView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: 500))
		frame.navigation.titleView = titleView

		let recognizer = UITapGestureRecognizer(target: frame.target(action: action), action: frame.action)
		titleView.isUserInteractionEnabled = true
		titleView.addGestureRecognizer(recognizer)
	}

	static let zero = FrameBarTitleText(text: DynamicBindings.Literal.zero, attributes: nil, action: nil)
}



class FrameBarTitleFragment: FrameBarTitle {
	init(element: DeclarationElement, context: DeclarationContext) throws {

	}



	override func apply(frame: FrameBuilder) {
		super.apply(frame: frame)
	}
}


