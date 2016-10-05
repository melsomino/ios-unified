//
// Created by Michael Vlasov on 14.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit




open class DefaultCentralUI: Dependent, CentralUI, DefaultMenuItemDelegate {


	open var dependency: DependencyResolver! {
		didSet {
			dependency.resolve(alerts)
		}
	}

	// MARK: - CentralUi


	open var rootController: UIViewController {
		return defaultRootController
	}

	open var contentContainer: UIView {
		return defaultRootController.contentContainer
	}


	open func execute(_ action: CentralUIAction) {
		switch action {
			case .run(let action):
				action(dependency)
			case .setContent(let controllerFactory):
				setContent(controllerFactory(dependency), animation: .fade, completion: nil)
		}
	}

	open func addMenuItem(_ name: String, title: String, icon: UIImage?, action: CentralUIAction) {
		let item = DefaultMenuItem(delegate: self, index: items.count, name: name, action: action)
		item.icon = icon
		item.title = title
		items.append(item)
	}


	open func findMenuItem(_ name: String) -> CentralUIMenuItem? {
		for item in items {
			if item.name.caseInsensitiveCompare(name) == .orderedSame {
				return item
			}
		}
		return nil
	}


	open var menuItemCount: Int {
		return items.count
	}

	open func menuItemAtIndex(_ index: Int) -> CentralUIMenuItem {
		return items[index]
	}


	open var selectedMenuItem: CentralUIMenuItem? {
		didSet {
			let oldIndex = oldValue?.index
			let newIndex = selectedMenuItem?.index

			OperationQueue.main.addOperation {
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


	open func createMenuIntegrationBarButtonItem() -> UIBarButtonItem {
		return UIBarButtonItem(image: CentralUIDesign.barButtonImage, style: .plain, target: self, action: #selector(showSideMenu))
	}


	open var accountIcon: UIImage?
	open var accountTitle: String?
	open var settingsAction: CentralUIAction?
	open var accountAction: CentralUIAction?

	open func setContent(_ controller: UIViewController?, animation: CentralUIContentAnimation, completion: (() -> Void)?) {
		defaultRootController.setContentController(controller, animation: animation, completion: completion)
	}


	open func pushAlert(_ alert: CentralUIAlert, message: String, icon: UIImage?, actionArg: Any?, action: ((Any?) -> Void)?) {
		alerts.pushInContainer(rootController.view, alert: alert, message: message, icon: icon, actionArg: actionArg, action: action)
	}


	// MARK: - DefaultMenuItem Delegate


	func onMenuItemChanged(_ menuItem: DefaultMenuItem) {
	}


	// MARK: - Internals

	var items = [DefaultMenuItem]()
	open lazy var defaultRootController: CentralUIRootController = CentralUIRootController()
	open let alerts = AlertStack()

	@objc func showSideMenu() {
		CentralUISideController.show(self)
	}
}


extension DependencyContainer {
	public func createDefaultCentralUI() {
		register(CentralUIDependency, DefaultCentralUI())
	}
}
