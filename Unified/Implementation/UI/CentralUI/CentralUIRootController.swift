//
// Created by Michael Vlasov on 30.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit


public class CentralUIRootController: UIViewController {

	public lazy var contentContainer: UIView = {
		[unowned self] in
		let container = UIView(frame: self.view.bounds)
		container.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
		self.view.addSubview(container)
		return container
	}()



	public func setContentController(newController: UIViewController!, animation: CentralUIContentAnimation, completion: (() -> Void)?) {
		guard newController != contentController else {
			return
		}
		let oldController = contentController
		contentController = newController

		CentralUIAnimations.contentTransition(from: oldController, to: newController, containerController: self, containerView: contentContainer,
			animation: animation, completion: completion)
	}



	public private(set) var contentController: UIViewController!
}
