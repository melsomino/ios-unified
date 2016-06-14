//
// Created by Michael Vlasovon 08.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit


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
}


public class SplitControllerFix: UISplitViewControllerDelegate {


	@objc public func splitViewController(svc: UISplitViewController, shouldHideViewController vc: UIViewController, inOrientation orientation: UIInterfaceOrientation) -> Bool {
		//TODO: Бага в режиме SplitView на iPad Air 2, iPad Pro на iOS 9. Не показывает Master у SplitView в режиме 3:1.
		return false
	}



	@objc public func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
		if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
			return true
		}
		else {
			return false
		}
	}
}

private let splitControllerFix = SplitControllerFix()

extension UIStoryboard {
	public static func createInitialControllerInStoryboard<Controller: UIViewController>(name: String, forClass: AnyClass, dependency: DependencyResolver) -> Controller {
		let storyboard = UIStoryboard(name: name, bundle: NSBundle(forClass: forClass))
		let controller = storyboard.instantiateInitialViewController()!
		let target = controller.unwrap() as Controller
		dependency.resolve(target as! DependentObject)
		if let split = controller as? UISplitViewController {
			split.preferredDisplayMode = .AllVisible
			split.delegate = splitControllerFix
		}
		return target
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