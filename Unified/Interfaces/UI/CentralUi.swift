//
// Created by Michael Vlasov on 14.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit





public enum CentralUiContentAnimation {
	case None, Fade, FromDown, FromUp
}





public enum CentralUiAction {
	case Run((DependencyResolver) -> Void)
	case SetContent((DependencyResolver) -> UIViewController)
}





public protocol CentralUiMenuItem {
	var index: Int { get }
	var name: String { get }
	var action: CentralUiAction { get }
	var title: String { get set }
	var icon: UIImage? { get set }
	var importantCount: Int? { get set }
	var totalCount: Int? { get set }
}





public enum CentralUiAlert {
	case Information, Warning, Error
}





public protocol CentralUi: class {

	var rootController: UIViewController { get }
	var contentContainer: UIView { get }

	func execute(action: CentralUiAction)

	// MARK: - Menu


	func addMenuItem(name: String, title: String, icon: UIImage?, action: CentralUiAction)


	func findMenuItem(name: String) -> CentralUiMenuItem?
	var menuItemCount: Int { get }
	func menuItemAtIndex(index: Int) -> CentralUiMenuItem
	var selectedMenuItem: CentralUiMenuItem? { get set }
	func createMenuIntegrationBarButtonItem() -> UIBarButtonItem


	// MARK: - Bottom Bar


	var accountIcon: UIImage? { get set }
	var accountTitle: String? { get set }
	var settingsAction: CentralUiAction? { get set }
	var accountAction: CentralUiAction? { get set }


	// MARK: - Content


	func setContent(controller: UIViewController?, animation: CentralUiContentAnimation, completion: (() -> Void)?)


	// MARK: - Alerts


	func pushAlert(alert: CentralUiAlert, message: String, icon: UIImage?, actionArg: Any?, action: ((Any?) -> Void)?)

}





extension CentralUi {
	public func pushAlert(alert: CentralUiAlert, message: String, icon: UIImage) {
		pushAlert(alert, message: message, icon: icon, actionArg: nil, action: nil)
	}
	public func pushAlert(alert: CentralUiAlert, message: String) {
		pushAlert(alert, message: message, icon: nil, actionArg: nil, action: nil)
	}
}


public let CentralUiDependency = Dependency<CentralUi>()

public protocol CentralUiDependent: Dependent {
}

extension CentralUiDependent {

	public var centralUi: CentralUi {
		return dependency.required(CentralUiDependency)
	}

	public var optionalCentralUi: CentralUi? {
		return dependency.optional(CentralUiDependency)
	}
}
