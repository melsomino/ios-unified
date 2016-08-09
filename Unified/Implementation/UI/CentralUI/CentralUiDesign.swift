//
// Created by Michael Vlasov on 27.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class CentralUIDesign {

	public static var bundle: NSBundle {
		return NSBundle(forClass: CentralUIDesign.self)
	}

	public static func imageNamed(name: String) -> UIImage? {
		return UIImage(named: name, inBundle: bundle, compatibleWithTraitCollection: nil)
	}

	public static let barButtonImage = CentralUIDesign.imageNamed("CentralUiMenu")
	public static let logoutImage = CentralUIDesign.imageNamed("CentralUiMenuLogout")

	public static let alertInformationIcon = CentralUIDesign.imageNamed("CentralUiAlertInformation")
	public static let alertWarningIcon = CentralUIDesign.imageNamed("CentralUiAlertWarning")
	public static let alertErrorIcon = CentralUIDesign.imageNamed("CentralUiAlertError")

	public static let backgroundColor = UIColor.parse("00283b")
	public static let separatorColor = UIColor.parse("004666")
	public static let selectionBackgroundColor = UIColor.parse("002335")
	public static let selectedItemIndicatorColor = UIColor.parse("ff7033")

	public static let informationPanelHeight = CGFloat(64)
	public static let informationPanelFont =  UIFont.systemFontOfSize(13)
	public static let informationPanelTextColor =  UIColor.whiteColor()
	public static let informationPanelBackgroundColor = UIColor.orangeColor()
	public static let informationPanelCloseButtonBackgroundColor =  UIColor.parse("ffb898")
	public static let informationPanelCloseButtonImage = CentralUIDesign.imageNamed("CentralUiCloseAlert")!.resizedToFitSize(CGSizeMake(6, 6))
}
