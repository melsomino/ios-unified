//
// Created by Власов М.Ю. on 08.06.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import UIKit


public enum PopoverAnchor {
	case None
	case BarButton(UIBarButtonItem)
	case Frame(CGRect)
	case View(UIView)
}

extension UIViewController {
	public var wrapper: UIViewController {
		if let split = splitViewController {
			return split
		}
		if let navigation = navigationController {
			return navigation
		}
		return self
	}

	public func unwrap<T>() -> T {
		switch self {
			case let target as T:
				return target
			case let navigation as UINavigationController:
				return navigation.topViewController!.unwrap() as T
			case let split as UISplitViewController:
				return split.childViewControllers[0].unwrap() as T

			default:
				fatalError("can not unwrap controller to \(String(T.self))")
		}
	}


	public func showDetails(controller: UIViewController) {
		if let split = splitViewController {
			split.showDetailViewController(controller.wrapper, sender: nil)
			return
		}
		if let navigation = navigationController {
			navigation.pushViewController(controller.wrapper, animated: true)
		}
		presentViewController(controller.wrapper, animated: true, completion: nil)

	}



	public func dismisDetails() {

	}



	public func showModal(controller: UIViewController, width: CGFloat?, anchor: PopoverAnchor = .None) {
		let wrapper = controller.wrapper
		wrapper.modalPresentationStyle = UIModalPresentationStyle.Popover
		if let popover = wrapper.popoverPresentationController {
			switch anchor {
				case .BarButton(let barButton):
					popover.barButtonItem = barButton
				case .View(let view):
					popover.sourceView = view
				case .Frame(let frame):
					popover.sourceRect = frame
				default:
					break
			}
			if let popoverDelegate = controller as? UIPopoverPresentationControllerDelegate {
				popover.delegate = popoverDelegate
			}
		}
		presentViewController(wrapper, animated: true, completion: nil)
	}


}


public class SplitControllerFix: UISplitViewControllerDelegate {


	@objc public func splitViewController(svc: UISplitViewController, shouldHideViewController vc: UIViewController, inOrientation orientation: UIInterfaceOrientation) -> Bool {
		//TODO: Бага в режиме SplitView на iPad Air 2, iPad Pro на iOS 9. Не показывает Master у SplitView в режиме 3:1.
		return false
	}



	@objc public func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
		return true
	}
}

private let splitControllerFix = SplitControllerFix()

extension UIStoryboard {

	private static func createController<Controller:UIViewController>(create: (UIStoryboard) -> UIViewController, inStoryboard storyboardName: String, dependency: DependencyResolver, initialization: ((Controller) -> Void)?) -> Controller {
		let storyboard = UIStoryboard(name: storyboardName, bundle: NSBundle(forClass: Controller.self))
		let controller = create(storyboard)
		let target = controller.unwrap() as Controller
		dependency.resolve(target)
		initialization?(target)
		if let split = controller as? UISplitViewController {
			split.preferredDisplayMode = .AllVisible
			split.delegate = splitControllerFix
		}
		return target
	}



	public static func createControllerWithId<Controller:UIViewController>(id: String, inStoryboard storyboardName: String, dependency: DependencyResolver, initialization: ((Controller) -> Void)?) -> Controller {
		return createController({ $0.instantiateViewControllerWithIdentifier(id) }, inStoryboard: storyboardName, dependency: dependency, initialization: initialization) as Controller
	}

	public static func createInitialControllerInStoryboard<Controller:UIViewController>(name: String, dependency: DependencyResolver, initialization: ((Controller) -> Void)?) -> Controller {
		return createController({ $0.instantiateInitialViewController()! }, inStoryboard: name, dependency: dependency, initialization: initialization) as Controller
	}
}



extension UIView {
	func nearestSuperview<Superview>() -> Superview? {
		var test = superview
		while test != nil {
			if let found = test as? Superview {
				return found
			}
			test = test!.superview
		}
		return nil
	}

}


extension UIImage {

	func resizedToFitSize(bounds: CGSize) -> UIImage {
		let ratio = max(bounds.width / size.width, bounds.height / size.height)
		let thumbnailSize = CGSizeMake(size.width * ratio, size.height * ratio)

		UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, UIScreen.mainScreen().scale);
		drawInRect(CGRectMake(0, 0, thumbnailSize.width, thumbnailSize.height))
		let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return thumbnail
	}

}