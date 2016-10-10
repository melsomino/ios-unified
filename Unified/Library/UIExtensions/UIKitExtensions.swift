//
// Created by Власов М.Ю. on 08.06.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import UIKit

public enum DetailsDecorations {
	case none
	case navigation

	public func decorate(_ controller: UIViewController) -> UIViewController {
		switch self {
			case .none:
				return controller
			case .navigation:
				return UINavigationController(rootViewController: controller)
		}
	}
}




public enum PopoverAnchor {
	case none
	case barButton(UIBarButtonItem)
	case frame(CGRect)
	case view(UIView)
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
				fatalError("can not unwrap controller to \(String(describing: T.self))")
		}
	}


	public func showDetails(_ controller: UIViewController, decorations: DetailsDecorations) {
		if let split = splitViewController {
			split.showDetailViewController(decorations.decorate(controller), sender: nil)
			return
		}

		if let navigation = navigationController {
			navigation.pushViewController(controller, animated: true)
			return
		}

		present(decorations.decorate(controller), animated: true, completion: nil)

	}



	public func dismissDetails() {

	}



	public func showModal(_ controller: UIViewController, width: CGFloat?, anchor: PopoverAnchor = .none) {
		let wrapper = controller.wrapper
		wrapper.modalPresentationStyle = UIModalPresentationStyle.popover
		if let popover = wrapper.popoverPresentationController {
			switch anchor {
				case .barButton(let barButton):
					popover.barButtonItem = barButton
				case .view(let view):
					popover.sourceView = view
				case .frame(let frame):
					popover.sourceRect = frame
				default:
					break
			}
			if let popoverDelegate = controller as? UIPopoverPresentationControllerDelegate {
				popover.delegate = popoverDelegate
			}
		}
		present(wrapper, animated: true, completion: nil)
	}


}


open class SplitControllerFix: UISplitViewControllerDelegate {


	@objc open func splitViewController(_ svc: UISplitViewController, shouldHide vc: UIViewController, in orientation: UIInterfaceOrientation) -> Bool {
		//TODO: Бага в режиме SplitView на iPad Air 2, iPad Pro на iOS 9. Не показывает Master у SplitView в режиме 3:1.
		return false
	}



	@objc open func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
		return true
	}
}

private let splitControllerFix = SplitControllerFix()

extension UIStoryboard {

	private static func createController<Controller:UIViewController>(_ create: (UIStoryboard) -> UIViewController, inStoryboard storyboardName: String, dependency: DependencyResolver, initialization: ((Controller) -> Void)?) -> Controller {
		let storyboard = UIStoryboard(name: storyboardName, bundle: Bundle(for: Controller.self))
		let controller = create(storyboard)
		let target = controller.unwrap() as Controller
		dependency.resolve(target)
		initialization?(target)
		if let split = controller as? UISplitViewController {
			split.preferredDisplayMode = .allVisible
			split.delegate = splitControllerFix
		}
		return target
	}



	public static func createControllerWithId<Controller:UIViewController>(_ id: String, inStoryboard storyboardName: String, dependency: DependencyResolver, initialization: ((Controller) -> Void)?) -> Controller {
		return createController({ $0.instantiateViewController(withIdentifier: id) }, inStoryboard: storyboardName, dependency: dependency, initialization: initialization) as Controller
	}

	public static func createInitialControllerInStoryboard<Controller:UIViewController>(_ name: String, dependency: DependencyResolver, initialization: ((Controller) -> Void)?) -> Controller {
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

	func resizedToFitSize(_ bounds: CGSize) -> UIImage {
		let ratio = max(bounds.width / size.width, bounds.height / size.height)
		let thumbnailSize = CGSize(width: size.width * ratio, height: size.height * ratio)

		UIGraphicsBeginImageContextWithOptions(thumbnailSize, false, UIScreen.main.scale);
		draw(in: CGRect(x: 0, y: 0, width: thumbnailSize.width, height: thumbnailSize.height))
		let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return thumbnail!
	}

}


extension UIColor {
	public static func parse(_ string: String) -> UIColor {
		if let named = UIColor.colorsByName[string.lowercased()] {
			return named
		}
		let hex = string.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		var int = UInt32()
		Scanner(string: hex).scanHexInt32(&int)
		let a, r, g, b: UInt32
		switch hex.characters.count {
			case 3: // RGB (12-bit)
				(a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
			case 6: // RGB (24-bit)
				(a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
			case 8: // ARGB (32-bit)
				(a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
			default:
				(a, r, g, b) = (1, 1, 1, 0)
		}
		return UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
	}


	private static let colorsByName = [
		"black": UIColor.black,
		"darkGray": UIColor.darkGray,
		"lightGray": UIColor.lightGray,
		"white": UIColor.white,
		"gray": UIColor.gray,
		"red": UIColor.red,
		"green": UIColor.green,
		"blue": UIColor.blue,
		"cyan": UIColor.cyan,
		"yellow": UIColor.yellow,
		"magenta": UIColor.magenta,
		"orange": UIColor.orange,
		"purple": UIColor.purple,
		"brown": UIColor.brown,
		"clear": UIColor.clear
	]
}
