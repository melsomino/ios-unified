//
// Created by Michael Vlasov on 14.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit




public class DefaultCentralUI: Dependent, CentralUI, DefaultMenuItemDelegate {


	public var dependency: DependencyResolver! {
		didSet {
			dependency.resolve(alerts)
		}
	}

	// MARK: - CentralUi


	public var rootController: UIViewController {
		return defaultRootController
	}

	public var contentContainer: UIView {
		return defaultRootController.contentContainer
	}


	public func execute(action: CentralUIAction) {
		switch action {
			case .run(let action):
				action(dependency)
			case .setContent(let controllerFactory):
				setContent(controllerFactory(dependency), animation: .fade, completion: nil)
		}
	}

	public func addMenuItem(name: String, title: String, icon: UIImage?, action: CentralUIAction) {
		let item = DefaultMenuItem(delegate: self, index: items.count, name: name, action: action)
		item.icon = icon
		item.title = title
		items.append(item)
	}


	public func findMenuItem(name: String) -> CentralUIMenuItem? {
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

	public func menuItemAtIndex(index: Int) -> CentralUIMenuItem {
		return items[index]
	}


	public var selectedMenuItem: CentralUIMenuItem? {
		didSet {
			let oldIndex = oldValue?.index
			let newIndex = selectedMenuItem?.index

			NSOperationQueue.mainQueue().addOperationWithBlock {
				var effect = CentralUIContentAnimation.fade
				if oldIndex != nil && newIndex != nil {
					effect = newIndex! < oldIndex! ? .fromUp : .fromDown
				}
				if let item = self.selectedMenuItem as? DefaultMenuItem {
					switch item.action {
						case .setContent(let controllerFactory):
							if item.contentController == nil {
								item.contentController = controllerFactory(self.dependency)
							}
							self.setContent(item.contentController!, animation: effect, completion: nil)
							break
						case .run(let run):
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
		return UIBarButtonItem(image: CentralUIDesign.barButtonImage, style: .Plain, target: self, action: #selector(showSideMenu))
	}


	public var accountIcon: UIImage?
	public var accountTitle: String?
	public var settingsAction: CentralUIAction?
	public var accountAction: CentralUIAction?

	public func setContent(controller: UIViewController?, animation: CentralUIContentAnimation, completion: (() -> Void)?) {
		defaultRootController.setContentController(controller, animation: animation, completion: completion)
	}


	public func pushAlert(alert: CentralUIAlert, message: String, icon: UIImage?, actionArg: Any?, action: (Any? -> Void)?) {
		alerts.pushInContainer(rootController.view, alert: alert, message: message, icon: icon, actionArg: actionArg, action: action)
	}


	// MARK: - DefaultMenuItem Delegate


	func onMenuItemChanged(menuItem: DefaultMenuItem) {
	}


	// MARK: - Internals

	var items = [DefaultMenuItem]()
	public lazy var defaultRootController: CentralUIRootController = CentralUIRootController()
	public let alerts = AlertStack()

	@objc func showSideMenu() {
		CentralUISideController.show(self)
	}
}


extension DependencyContainer {
	public func createDefaultCentralUI() {
		register(CentralUIDependency, DefaultCentralUI())
	}
}
