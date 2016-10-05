//
// Created by Michael Vlasov on 10.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

protocol DefaultMenuItemDelegate: AnyObject {
	func onMenuItemChanged(_ menuItem: DefaultMenuItem)
}

class DefaultMenuItem: CentralUIMenuItem {
	let delegate: DefaultMenuItemDelegate?
	let index: Int
	let name: String
	let action: CentralUIAction
	var contentController: UIViewController?

	init(delegate: DefaultMenuItemDelegate?, index: Int, name: String, action: CentralUIAction) {
		self.delegate = delegate
		self.index = index
		self.name = name
		self.action = action
	}



	var title = "" {
		didSet {
			delegate?.onMenuItemChanged(self)
		}
	}

	var icon: UIImage? {
		didSet {
			delegate?.onMenuItemChanged(self)
		}
	}

	var importantCount: Int? {
		didSet {
			delegate?.onMenuItemChanged(self)
		}
	}

	var totalCount: Int? {
		didSet {
			delegate?.onMenuItemChanged(self)
		}
	}



}


