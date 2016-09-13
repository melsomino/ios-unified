//
// Created by Michael Vlasov on 14.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit





public enum CentralUIContentAnimation {
	case none, fade, fromDown, fromUp
}





public enum CentralUIAction {
	case run((DependencyResolver) -> Void)
	case setContent((DependencyResolver) -> UIViewController)
}





public protocol CentralUIMenuItem {
	var index: Int { get }
	var name: String { get }
	var action: CentralUIAction { get }
	var title: String { get set }
	var icon: UIImage? { get set }
	var importantCount: Int? { get set }
	var totalCount: Int? { get set }
}





public enum CentralUIAlert {
	case information, warning, error, success
}





public protocol CentralUI: class {

	var rootController: UIViewController { get }
	var contentContainer: UIView { get }

	func execute(action: CentralUIAction)

	// MARK: - Menu


	func addMenuItem(name: String, title: String, icon: UIImage?, action: CentralUIAction)


	func findMenuItem(name: String) -> CentralUIMenuItem?
	var menuItemCount: Int { get }
	func menuItemAtIndex(index: Int) -> CentralUIMenuItem
	var selectedMenuItem: CentralUIMenuItem? { get set }
	func createMenuIntegrationBarButtonItem() -> UIBarButtonItem


	// MARK: - Bottom Bar


	var accountIcon: UIImage? { get set }
	var accountTitle: String? { get set }
	var settingsAction: CentralUIAction? { get set }
	var accountAction: CentralUIAction? { get set }


	// MARK: - Content


	func setContent(controller: UIViewController?, animation: CentralUIContentAnimation, completion: (() -> Void)?)


	// MARK: - Alerts


	func pushAlert(alert: CentralUIAlert, message: String, icon: UIImage?, actionArg: Any?, action: ((Any?) -> Void)?)

}





extension CentralUI {
	public func pushAlert(alert: CentralUIAlert, message: String, icon: UIImage) {
		pushAlert(alert, message: message, icon: icon, actionArg: nil, action: nil)
	}
	public func pushAlert(alert: CentralUIAlert, message: String) {
		pushAlert(alert, message: message, icon: nil, actionArg: nil, action: nil)
	}
}


public let CentralUIDependency = Dependency<CentralUI>()

public protocol CentralUIDependent: Dependent {
}

extension CentralUIDependent {

	public var centralUI: CentralUI {
		return dependency.required(CentralUIDependency)
	}

	public var optionalCentralUI: CentralUI? {
		return dependency.optional(CentralUIDependency)
	}
}
