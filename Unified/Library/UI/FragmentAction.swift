//
// Created by Власов М.Ю. on 17.11.16.
//

import Foundation
import UIKit



public class FragmentActionContext {
	let dependency: DependencyResolver
	let delegate: FragmentDelegate
	let model: AnyObject
	let modelValues: [Any?]
	let reasonElement: FragmentElement?

	init(dependency: DependencyResolver, delegate: FragmentDelegate, model: AnyObject, modelValues: [Any?], reasonElement: FragmentElement?) {
		self.dependency = dependency
		self.delegate = delegate
		self.model = model
		self.modelValues = modelValues
		self.reasonElement = reasonElement
	}

	convenience init(element: FragmentElement) {
		let fragment = element.fragment!
		self.init(dependency: fragment.dependency, delegate: fragment.delegate!, model: fragment.model ?? NSNull(), modelValues: fragment.modelValues, reasonElement: element)
	}
}



open class FragmentAction {
	open func execute(context: FragmentActionContext) {
	}



	public final func execute(from element: FragmentElement) {
		execute(context: FragmentActionContext(element: element))
	}



	public static func from(element: DeclarationElement, context: DeclarationContext, name: String = "action") throws -> FragmentAction? {
		if let attribute = element.find(attribute: name) {
			return FragmentActionNameArgs(expression: try context.getExpression(attribute))
		}
		if let child = element.find(child: ".\(name)") {
			if child.find(attribute: "popover") != nil {
				return try FragmentActionPopover(element: child, context: context)
			}
			throw DeclarationError("Invalid action definition", element, context)
		}
		return nil
	}

}



class FragmentActionNameArgs: FragmentAction {
	let expression: DynamicBindings.Expression?

	init(expression: DynamicBindings.Expression?) {
		self.expression = expression
	}



	override func execute(context: FragmentActionContext) {
		context.delegate.onAction(routing: ActionRouting(expression: expression, values: context.modelValues))
	}

}



enum PopoverAppearance {
	case modal
	case screenCenter
	case screenSide(UIRectEdge)
	case element(UIRectEdge)
}



class FragmentActionPopover: FragmentAction {
	let fragmentDefinition: FragmentDefinition
	let appearance: PopoverAppearance

	init(element: DeclarationElement, context: DeclarationContext) throws {
		var appearance = PopoverAppearance.screenCenter
		if let attribute = element.find(attribute: "popover") {
			appearance = try context.getEnum(attribute, FragmentActionPopover.appearanceByName)
		}
		fragmentDefinition = try FragmentDefinition.from(element: element, startAttribute: 0, context: context)
		self.appearance = appearance
	}


	private static let appearanceByName: [String: PopoverAppearance] = [
		"modal": .modal,
		"screen-center": .screenCenter,
		"screen-left": .screenSide(.left),
		"screen-right": .screenSide(.right),
		"screen-top": .screenSide(.top),
		"screen-bottom": .screenSide(.bottom),
		"element-left": .element(.left),
		"element-right": .element(.right),
		"element-top": .element(.top),
		"element-bottom": .element(.bottom)
	]

	override func execute(context: FragmentActionContext) {
		let fragment = Fragment(definition: fragmentDefinition, dependency: context.dependency)
		fragment.model = context.model

		let controller = FragmentPopoverController()
		controller.context = context
		controller.fragment = fragment
		controller.modalPresentationStyle = .overCurrentContext
		context.delegate.controller.present(controller, animated: false) {
			controller.startShowAnimation()
		}
	}
}



public final class FragmentPopoverController: UIViewController, UIGestureRecognizerDelegate, FragmentDelegate {

	var context: FragmentActionContext!
	var fragment: Fragment!

	// MARK: - View Controller Overrides


	public override func viewDidLoad() {
		super.viewDidLoad()
		presenterNavigationController = context.delegate.controller.navigationController
		fragment.performLayout(inWidth: view.bounds.width)
		fragment.delegate = self
		view.backgroundColor = UIColor.clear
		let navigationBarHeight = getNavigationBarHeight()

		fragmentContainer = UIView(frame: view.bounds)
		fragmentContainer.isHidden = true
		fragmentContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		fragment.container = fragmentContainer

		let size = view.bounds.size
		var width = fragment.frame.width
		var left = size.width - width
		switch fragment.rootElement.horizontalAlignment {
			case .leading:
				left = 0
			case .center:
				left = size.width / 2 - width / 2
			case .fill:
				left = 0
				width = size.width
			default:
				break
		}

		let fragmentFrame = CGRect(x: left, y: navigationBarHeight, width: width, height: fragment.frame.height)
		outerContainer = UIScrollView(frame: fragmentFrame)
		outerContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		outerContainer.clipsToBounds = true

		outerContainer.addSubview(fragmentContainer)
		view.addSubview(outerContainer)

		let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(cancel))
		tapRecognizer.delegate = self
		view.addGestureRecognizer(tapRecognizer)

		fragment.performLayout(inBounds: fragmentFrame.size)
	}



	private func getNavigationBarHeight() -> CGFloat {
		let statusBarHeight = view.bounds.width < view.bounds.height ? 20 : 0
		return CGFloat(statusBarHeight) + (presenterNavigationController?.navigationBar.frame.size.height ?? 0)
	}



	public override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
	}


	// MARK: - Fragment Delegate


	public var controller: UIViewController! {
		return self
	}


	public func onAction(routing: ActionRouting) {
		context.delegate.onAction(routing: routing)
	}



	public func layoutChanged(forFragment fragment: Fragment) {
		fragment.performLayout()
	}


	// MARK: - Tap Gesture Delegate


	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		return !(touch.view?.isDescendant(of: outerContainer) ?? false)
	}



	// MARK: - Internals


	var outerContainer: UIScrollView!
	var fragmentContainer: UIView!
	var presenterNavigationController: UINavigationController?


	func cancel() {
		finish()
	}



	private func finish() {
		startHideAnimation() {
			self.dismiss(animated: false)
		}
	}



	final func startShowAnimation() {
		fragmentContainer.frame = outerContainer.bounds.offsetBy(dx: 0, dy: -outerContainer.bounds.size.height)
		fragmentContainer.isHidden = false
		UIView.animate(withDuration: 0.25, animations: {
			self.fragmentContainer.frame = self.outerContainer.bounds
		})
	}



	private func startHideAnimation(completion: @escaping () -> Void) {
		let visibleFrame = outerContainer.bounds
		fragmentContainer.frame = visibleFrame

		UIView.animate(withDuration: 0.25, animations: {
			self.fragmentContainer.frame = visibleFrame.offsetBy(dx: 0, dy: -visibleFrame.size.height)
		}, completion: {
			finished in
			completion()
		})
	}

}
