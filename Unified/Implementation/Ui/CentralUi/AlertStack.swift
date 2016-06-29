//
// Created by Michael Vlasov on 10.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit



public class AlertStack: Dependent {


	public var dependency: DependencyResolver!

	init() {
	}



	public func pushInContainer(container: UIView, icon: UIImage, message: String, actionArg: Any?, action: ((Any?) -> Void)?) {
		let newPanel = AlertPanel(frame: CGRectMake(0, -CentralUiDesign.informationPanelHeight, container.bounds.width, CentralUiDesign.informationPanelHeight))
		dependency.resolve(newPanel)
		newPanel.stack = self
		newPanel.ui.model = AlertModel(icon: icon, message: message, actionArg: actionArg, action: action)

		stack.insert(newPanel, atIndex: 0)
		container.addSubview(newPanel)

		let hideTime = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC * 3))
		weak var weakPanel = newPanel
		dispatch_after(hideTime, dispatch_get_main_queue()) {
			if let panel = weakPanel {
				self.hidePanelAnimated(panel)
			}
		}

		relocatePanelsAnimated()
	}


	func relocatePanelsAnimated() {
		guard stack.count > 0 else {
			return
		}

		let width = stack[0].bounds.width
		var requiresRealign = false
		var y = CGFloat(0)
		for panel in self.stack {
			if panel.frame.origin.y != y {
				requiresRealign = true
				break
			}
			y += CentralUiDesign.informationPanelHeight
		}

		guard requiresRealign else {
			return
		}

		UIView.animateWithDuration(NSTimeInterval(0.25)) {
			var frame = CGRectMake(0, 0, width, CentralUiDesign.informationPanelHeight)
			for panel in self.stack {
				panel.frame = frame
				frame.origin.y += CentralUiDesign.informationPanelHeight
			}
		}
	}


	func hidePanelAnimated(panel: AlertPanel) {
		guard stack.contains(panel) else {
			return
		}
		UIView.animateWithDuration(NSTimeInterval(0.25),
			animations: {
				panel.alpha = 0
			},
			completion: {
				finished in
				if let index = self.stack.indexOf(panel) {
					self.stack.removeAtIndex(index)
				}
				panel.removeFromSuperview()
				self.relocatePanelsAnimated()
			})
	}


	private var stack = [AlertPanel]()
}





public struct AlertModel {
	let icon: UIImage
	let message: String
	let actionArg: Any?
	let action: ((Any?) -> Void)?
}





class AlertPanel: UIView, Dependent, AlertUiDelegate {

	weak var stack: AlertStack?
	var ui = AlertUi()


	override init(frame: CGRect) {
		super.init(frame: frame)
		initialize()
	}


	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initialize()
	}


	func initialize() {
		userInteractionEnabled = true
		autoresizingMask = [.FlexibleWidth]
		ui.container = self
		ui.delegate = self

		addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapOnPanelRecognized(_:))))
	}


	override func layoutSubviews() {
		super.layoutSubviews()
		ui.performLayout(inBounds: bounds.size)
	}

	func onClose() {
		stack?.hidePanelAnimated(self)
	}


	@objc func tapOnPanelRecognized(sender: UITapGestureRecognizer) {
		guard sender.state == .Ended else {
			return
		}
		guard let stack = stack else {
			return
		}
		let location = sender.locationInView(self)
		if location.x < 36 {
			if let action = ui.model?.action {
				action(ui.model!.actionArg)
			}
		}
		stack.hidePanelAnimated(self)
	}

	// MARK: - Dependent

	var dependency: DependencyResolver! {
		didSet {
			dependency.resolve(ui)
		}
	}

}



protocol AlertUiDelegate: class {
	func onClose()
}

public class AlertUi: ModelUi<AlertModel> {

	weak var delegate: AlertUiDelegate?

	let icon = UiImage()
	let message = UiText()
	let closeButton = UiButton()

	override init() {
		super.init()
//		closeButton.onTouchUpInside = {
//			[unowned self] in
//			self.delegate?.onClose()
//		}
	}

	public override func onModelChanged() {
		message.text = model?.message
		icon.image = model?.icon
	}

}


