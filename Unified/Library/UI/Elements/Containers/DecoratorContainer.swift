//
// Created by Michael Vlasov on 01.08.16.
//

import Foundation
import UIKit
import QuartzCore





open class DecoratorElement: ContentElement {

	open var child: FragmentElement!

	open var padding = UIEdgeInsets.zero {
		didSet {
			initializeView()
		}
	}

	open var transparentGradientLeft: CGFloat? {
		didSet {
			initializeView()
		}
	}

	public final func reflectParentBackgroundTo(_ color: UIColor?) {
		if let view = view as? DecoratorView {
			view.reflectParentBackgroundTo(color)
		}
	}

	// MARK: - UiContentElement


	open override func createView() -> UIView {
		return DecoratorView()
	}


	open override func initializeView() {
		guard let view = view else {
			return
		}

		view.layer.borderWidth = borderWidth ?? 0
		view.layer.borderColor = (borderColor ?? UIColor.clear).cgColor

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


	open override var visible: Bool {
		if let child = child {
			return child.visible
		}
		return false
	}

	open override var includeInLayout: Bool {
		if hidden && !preserveSpace {
			return false
		}
		return child.includeInLayout
		
	}

	open override func traversal(_ visit: (FragmentElement) -> Void) {
		super.traversal(visit)
		child?.traversal(visit)
	}


	open override func measureContent(inBounds bounds: CGSize) -> SizeMeasure {
		let childBounds = FragmentElement.reduce(size: bounds, edges: padding)
		let childMeasure = child.measure(inBounds: childBounds)
		return FragmentElement.expand(measure: childMeasure, edges: padding)
	}


	open override func layoutContent(inBounds bounds: CGRect) {
		frame = bounds
		let childBounds = FragmentElement.reduce(rect: bounds, edges: padding)
		let childSize = child.measure(inBounds: childBounds.size)
		child.layout(inBounds: childBounds, usingMeasured: childSize.maxSize)
	}


}





open class DecoratorElementDefinition: ContentElementDefinition {
	var padding: UIEdgeInsets = UIEdgeInsets.zero
	var transparentGradientLeft: CGFloat?


	// MARK: - UiElementDefinition


	open override func applyDeclarationAttribute(_ attribute: DeclarationAttribute, isElementValue: Bool, context: DeclarationContext) throws {
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


	open override func createElement() -> FragmentElement {
		return DecoratorElement()
	}


	open override func initialize(_ element: FragmentElement, children: [FragmentElement]) {
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
		guard let gradient = gradient_layer, let left = transparentGradientLeft else {
			return
		}
		gradient.frame = bounds
		gradient.locations = gradientStops(0, bounds.width > 0 ? left / bounds.width : CGFloat(0), 1)
	}


	// MARK: - Internals


	private var gradient_layer: CAGradientLayer?
	private var default_background_color_assigned = false
	private var default_background_color: UIColor?

	private func gradientStops(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat) -> [NSNumber] {
		return [NSNumber(value: a.native), NSNumber(value: b.native), NSNumber(value: c.native)]
	}
	
	private func check_default_background_color_assigned() {
		if !default_background_color_assigned {
			default_background_color = backgroundColor
			default_background_color_assigned = true
		}
	}


	private func resolve_background_color() -> UIColor {
		check_default_background_color_assigned()
		return decoratorBackgroundColor ?? default_background_color ?? UIColor.clear
	}


	private func background_properties_changed() {
		check_default_background_color_assigned()

		if let left = transparentGradientLeft, let back_color = decoratorBackgroundColor {
			if gradient_layer == nil {
				layer.backgroundColor = UIColor.clear.cgColor
				gradient_layer = CAGradientLayer()
				layer.addSublayer(gradient_layer!)
				gradient_layer!.frame = bounds
			}
			let gradient = gradient_layer!
			gradient.startPoint = CGPoint(x: 0, y: 0.5)
			gradient.endPoint = CGPoint(x: 1, y: 0.5)

			gradient.colors = [back_color.withAlphaComponent(0).cgColor, back_color.cgColor, back_color.cgColor]
			gradient.locations = gradientStops(0, bounds.width > 0 ? left / bounds.width : CGFloat(0), 1)
		}
		else {
			if let gradient = gradient_layer {
				gradient.removeFromSuperlayer()
				gradient_layer = nil
			}
			layer.backgroundColor = resolve_background_color().cgColor
		}
	}


	final func reflectParentBackgroundTo(_ color: UIColor?) {
		guard transparentGradientLeft != nil else {
			return
		}
		guard let gradient = gradient_layer, let back_color = color ?? decoratorBackgroundColor else {
			return
		}
		gradient.colors = [back_color.withAlphaComponent(0).cgColor, back_color.cgColor, back_color.cgColor]
	}

}
