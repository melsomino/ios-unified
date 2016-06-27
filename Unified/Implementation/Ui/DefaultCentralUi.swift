//
// Created by Michael Vlasov on 14.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation





public class DefaultCentralUi: Dependent, CentralUi, DefaultMenuItemDelegate {


	public var dependency: DependencyResolver!

	// MARK: - CentralUi


	public var rootController: UIViewController {
		return defaultRootController
	}

	public var contentContainer: UIView {
		return defaultRootController.contentContainer
	}

	public func addMenuItem(name: String, title: String, icon: UIImage?, action: CentralUiAction) {
		let item = DefaultMenuItem(delegate: self, index: items.count, name: name, action: action)
		item.icon = icon
		item.title = title
		items.append(item)
	}


	public func findMenuItem(name: String) -> CentralUiMenuItem? {
		for item in items {
			if item.name.caseInsensitiveCompare(name) == .OrderedSame {
				return item
			}
		}
		return nil
	}


	public var menuItemCount: Int {
		return items.count
	}

	public func menuItemAtIndex(index: Int) -> CentralUiMenuItem {
		return items[index]
	}


	public var selectedMenuItem: CentralUiMenuItem? {
		didSet {
			let oldIndex = oldValue?.index
			let newIndex = selectedMenuItem?.index

			NSOperationQueue.mainQueue().addOperationWithBlock {
				var effect = CentralUiContentAnimation.Fade
				if oldIndex != nil && newIndex != nil {
					effect = newIndex! < oldIndex! ? .FromUp : .FromDown
				}
				if let item = self.selectedMenuItem as? DefaultMenuItem {
					switch item.action {
						case .Content(let controllerFactory):
							if item.contentController == nil {
								item.contentController = controllerFactory(self.dependency)
							}
							self.setContent(item.contentController!, animation: effect)
							break
						case .Run(let run):
							run(self.dependency)
							break
					}
				}
				else {
					self.setContent(nil, animation: effect, completion: nil)
				}
			}
		}
	}


	public func createMenuIntegrationBarButtonItem() -> UIBarButtonItem {
		return UIBarButtonItem(image: CentralUiDesign.barButtonImage, style: .Plain, target: self, action: #selector(showSideMenu))
	}


	public var accountIcon: UIImage? {
		get {
			return nil
		}
		set {
		}
	}


	public var accountTitle: String? {
		get {
			return nil
		}
		set {
		}
	}


	public var settingsAction: CentralUiAction? {
		get {
			return nil
		}
		set {
		}
	}


	public var accountAction: CentralUiAction? {
		get {
			return nil
		}
		set {
		}
	}


	public func setContent(controller: UIViewController?, animation: CentralUiContentAnimation) {
		defaultRootController.setContentController(controller, animation: animation, completion: completion)
	}


	public func pushAlert(alert: CentralUiAlert, message: String, icon: UIImage, actionArg: Any?, action: (Any? -> Void)?) {
		alerts.pushInContainer(rootController.view, icon: icon, message: message, actionArg: actionArg, action: action)
	}


	// MARK: - DefaultMenuItem Delegate

	func onMenuItemChanged(menuItem: DefaultMenuItem) {
	}


	// MARK: - Internals

	var items = [DefaultMenuItem]()
	public lazy var defaultRootController: MainMenuRootController = MainMenuRootController()
	public let alerts = AlertStack()

	@objc func showSideMenu() {

	}
}


extension DependencyContainer {
	public func createDefaultCentralUi() {
		register(CentralUiDependency, DefaultCentralUi())
	}
}
