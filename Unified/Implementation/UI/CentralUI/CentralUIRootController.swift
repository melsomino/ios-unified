//
// Created by Michael Vlasov on 30.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit


open class CentralUIRootController: UIViewController {

	open lazy var contentContainer: UIView = {
		[unowned self] in
		let container = UIView(frame: self.view.bounds)
		container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.view.addSubview(container)
		return container
	}()



	open func setContentController(_ newController: UIViewController!, animation: CentralUIContentAnimation, completion: (() -> Void)?) {
		guard newController != contentController else {
			return
		}
		let oldController = contentController
		contentController = newController

		CentralUIAnimations.contentTransition(from: oldController, to: newController, containerController: self, containerView: contentContainer,
			animation: animation, completion: completion)
	}



	open fileprivate(set) var contentController: UIViewController!
}
