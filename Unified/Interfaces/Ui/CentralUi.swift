//
// Created by Michael Vlasov on 14.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit





public enum CentralUiContentAnimation {
	case None, Fade, FromFown, FromUp
}





public enum CentralUiAction {
	case Run(() -> Void)
	case Content(() -> UIViewController)
}





public protocol CentralUiMenuItem {
	var name: String { get }
	var action: CentralUiAction { get }
	var title: String { get set }
	var icon: UIImage { get set }
	var importantCount: Int? { get set }
	var totalCount: Int? { get set }
}





public enum CentralUiAlert {
	case Information, Warning, Error
}





public protocol CentralUiTheme {

	// MARK: - Menu

	var menuBackgroundColor: UIColor { get set }
	var menuWidth: CGFloat { get set }
	var menuItemHeight: CGFloat { get set }
	var menuItemIconSize: CGSize { get set }
	var menuItemSpacing: CGSize { get set }
	var menuItemFont: UIFont { get set }
	var menuItemImportantCountFont: UIFont { get set }
	var menuItemTotalCountFont: UIFont { get set }
	var menuItemImportantCountTextColor: UIColor { get set }
	var menuItemTotalCountTextColor: UIColor { get set }
	var menuIntegrationIcon: UIImage { get set }

	// MARK: - Alert

	var alertHeight: CGFloat { get set }
	var alertPadding: UIEdgeInsets { get set }
	var alertIconSize: CGSize { get set }
	var alertSpacing: CGFloat { get set }
	var alertMessageFont: UIFont { get set }
	var alertInformationTextColor: UIFont { get set }
	var alertWarningTextColor: UIFont { get set }
	var alertErrorTextColor: UIFont { get set }
	var alertInformationLowAccentTextColor: UIFont { get set }
	var alertWarningLowAccentTextColor: UIFont { get set }
	var alertErrorLowAccentTextColor: UIFont { get set }
	var alertInformationBackgroundColor: UIColor { get set }
	var alertWarningBackgroundColor: UIColor { get set }
	var alertErrorBackgroundColor: UIColor { get set }

	// MARK: - Bottom

	var bottomBarHeight: CGFloat { get set }
	var bottomBarSettingsIcon: UIImage { get set }
}





public protocol CentralUi {

	var theme: CentralUiTheme { get }


	// MARK: - Menu


	func addMenuItem(name: String, title: String, icon: UIImage, action: CentralUiAction)


	func findMenuItem(name: String) -> CentralUiMenuItem?
	var menuItems: [CentralUiMenuItem] { get }
	var selectedMenuItem: CentralUiMenuItem? { get set }
	func createMenuIntegrationBarButtonItem() -> UIBarButtonItem


	// MARK: - Bottom Bar


	var accountIcon: UIImage? { get set }
	var accountTitle: String? { get set }
	var settingsAction: CentralUiAction? { get set }
	var accountAction: CentralUiAction? { get set }


	// MARK: - Content


	func setContent(controller: UIViewController, animation: CentralUiContentAnimation)


	// MARK: - Alerts


	func pushAlert(alert: CentralUiAlert, message: String, icon: UIImage, actionArg: Any?, action: ((Any?) -> Void)?)

}





extension CentralUi {
	public func pushAlert(alert: CentralUiAlert, message: String, icon: UIImage) {
		pushAlert(alert, message: message, icon: icon, actionArg: nil, action: nil)
	}
}
