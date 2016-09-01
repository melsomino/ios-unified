//
// Created by Michael Vlasov on 01.08.16.
//

import Foundation
import UIKit
import QuartzCore





public class DecoratorElement: ContentElement {

	public var child: FragmentElement!

	public var padding = UIEdgeInsetsZero {
		didSet {
			initializeView()
		}
	}

	public var transparentGradientLeft: CGFloat? {
		didSet {
			initializeView()
		}
	}

	public final func reflectParentBackgroundTo(color: UIColor?) {
		if let view = view as? DecoratorView {
			view.reflectParentBackgroundTo(color)
		}
	}

	// MARK: - UiContentElement


	public override func createView() -> UIView {
		return DecoratorView()
	}


	public override func initializeView() {
		guard let view = view else {
			return
		}

		view.layer.borderWidth = borderWidth ?? 0
		view.layer.borderColor = (borderColor ?? UIColor.clearColor()).CGColor

		if let radius = cornerRadius {
			view.clipsToBounds = true
			view.layer.cornerRadius = radius
		}
		else {
			view.layer.cornerRadius = 0
		}

		guard let decorator = view as? DecoratorView else {
			return
		}

		decorator.decoratorBackgroundColor = backgroundColor
		decorator.transparentGradientLeft = transparentGradientLeft
	}




	// MARK: - UiElement


	public override var visible: Bool {
		if let child = child {
			return child.visible
		}
		return false
	}


	public override func traversal(@noescape visit: (FragmentElement) -> Void) {
		super.traversal(visit)
		child?.traversal(visit)
	}


	public override func measureContent(inBounds bounds: CGSize) -> CGSize {
		guard visible else {
			return CGSizeZero
		}
		return FragmentElement.expand(size: child.measure(inBounds: FragmentElement.reduce(size: bounds, edges: padding)), edges: padding)
	}


	public override func layoutContent(inBounds bounds: CGRect) {
		frame = bounds
		let childBounds = FragmentElement.reduce(rect: bounds, edges: padding)
		let childSize = child.measure(inBounds: childBounds.size)
		child.layout(inBounds: childBounds, usingMeasured: childSize)
	}


}





public class DecoratorElementDefinition: ContentElementDefinition {
	var padding: UIEdgeInsets = UIEdgeInsetsZero
	var transparentGradientLeft: CGFloat?


	// MARK: - UiElementDefinition


	public override func applyDeclarationAttribute(attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
		switch attribute.name {
			case "transparent-gradient-left":
				transparentGradientLeft = try context.getFloat(attribute)
			default:
				if try context.applyInsets(&padding, name: "padding", attribute: attribute) {
				}
				else {
					try super.applyDeclarationAttribute(attribute, isElementValue: isElementValue, context: context)
				}
		}
	}


	public override func createElement() -> FragmentElement {
		return DecoratorElement()
	}


	public override func initialize(element: FragmentElement, children: [FragmentElement]) {
		super.initialize(element, children: children)

		let decorator = element as! DecoratorElement

		decorator.borderWidth = borderWidth
		decorator.borderColor = borderColor
		decorator.padding = padding
		decorator.transparentGradientLeft = transparentGradientLeft
		decorator.child = children[0]
	}


}





class DecoratorView: UIView {


	var transparentGradientLeft: CGFloat? {
		didSet {
			background_properties_changed()
		}
	}

	var decoratorBackgroundColor: UIColor? {
		didSet {
			background_properties_changed()
		}
	}


	// MARK: - UIView


	override func layoutSubviews() {
		super.layoutSubviews()
		guard let gradient = gradient_layer, left = transparentGradientLeft else {
			return
		}
		gradient.frame = bounds
		gradient.locations = [0, bounds.width > 0 ? left / bounds.width : 0, 1]
	}


	// MARK: - Internals


	private var gradient_layer: CAGradientLayer?
	private var default_background_color_assigned = false
	private var default_background_color: UIColor?

	private func check_default_background_color_assigned() {
		if !default_background_color_assigned {
			default_background_color = backgroundColor
			default_background_color_assigned = true
		}
	}


	private func resolve_background_color() -> UIColor {
		check_default_background_color_assigned()
		return decoratorBackgroundColor ?? default_background_color ?? UIColor.clearColor()
	}


	private func background_properties_changed() {
		check_default_background_color_assigned()

		if let left = transparentGradientLeft, back_color = decoratorBackgroundColor {
			if gradient_layer == nil {
				layer.backgroundColor = UIColor.clearColor().CGColor
				gradient_layer = CAGradientLayer()
				layer.addSublayer(gradient_layer!)
				gradient_layer!.frame = bounds
			}
			let gradient = gradient_layer!
			gradient.startPoint = CGPointMake(0, 0.5)
			gradient.endPoint = CGPointMake(1, 0.5)

			gradient.colors = [back_color.colorWithAlphaComponent(0).CGColor, back_color.CGColor, back_color.CGColor]
			gradient.locations = [0, bounds.width > 0 ? left / bounds.width : 0, 1]
		}
		else {
			if let gradient = gradient_layer {
				gradient.removeFromSuperlayer()
				gradient_layer = nil
			}
			layer.backgroundColor = resolve_background_color().CGColor
		}
	}


	final func reflectParentBackgroundTo(color: UIColor?) {
		guard transparentGradientLeft != nil else {
			return
		}
		guard let gradient = gradient_layer, back_color = color ?? decoratorBackgroundColor else {
			return
		}
		gradient.colors = [back_color.colorWithAlphaComponent(0).CGColor, back_color.CGColor, back_color.CGColor]
	}

}