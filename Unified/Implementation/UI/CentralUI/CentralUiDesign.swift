//
// Created by Michael Vlasov on 27.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

open class CentralUIDesign {

	open static var bundle: Bundle {
		return Bundle(for: CentralUIDesign.self)
	}

	open static func imageNamed(_ name: String) -> UIImage? {
		return UIImage(named: name, in: bundle, compatibleWith: nil)
	}

	open static let barButtonImage = CentralUIDesign.imageNamed("CentralUiMenu")
	open static let logoutImage = CentralUIDesign.imageNamed("CentralUiMenuLogout")

	open static let alertInformationIcon = CentralUIDesign.imageNamed("CentralUiAlertInformation")
	open static let alertWarningIcon = CentralUIDesign.imageNamed("CentralUiAlertWarning")
	open static let alertErrorIcon = CentralUIDesign.imageNamed("CentralUiAlertError")

	open static let backgroundColor = UIColor.parse("00283b")
	open static let separatorColor = UIColor.parse("004666")
	open static let selectionBackgroundColor = UIColor.parse("002335")
	open static let selectedItemIndicatorColor = UIColor.parse("ff7033")

	open static let informationPanelHeight = CGFloat(64)
	open static let informationPanelFont =  UIFont.systemFont(ofSize: 13)
	open static let informationPanelTextColor =  UIColor.white
	open static let informationPanelBackgroundColor = UIColor.orange
	open static let informationPanelCloseButtonBackgroundColor =  UIColor.parse("ffb898")
	open static let informationPanelCloseButtonImage = CentralUIDesign.imageNamed("CentralUiCloseAlert")!.resizedToFitSize(CGSize(width: 6, height: 6))
}
