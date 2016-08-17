//
// Created by Michael Vlasov on 10.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit



public class AlertStack: Dependent {


	public var dependency: DependencyResolver!

	public init() {
	}



	public func pushInContainer(container: UIView, alert: CentralUIAlert, message: String, icon: UIImage?, actionArg: Any?, action: ((Any?) -> Void)?) {
		var icon = icon
		if icon == nil {
			switch alert {
				case .error:
					icon = CentralUIDesign.alertErrorIcon
				case .warning:
					icon = CentralUIDesign.alertWarningIcon
				case .information:
					icon = CentralUIDesign.alertInformationIcon
			}
		}
		let newPanel = AlertPanel(frame: CGRectMake(0, -CentralUIDesign.informationPanelHeight, container.bounds.width, CentralUIDesign.informationPanelHeight))
		newPanel.dependency = dependency
		newPanel.stack = self
		newPanel.ui.model = Alert(icon: icon!, message: message, actionArg: actionArg, action: action)

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
			y += CentralUIDesign.informationPanelHeight
		}

		guard requiresRealign else {
			return
		}

		UIView.animateWithDuration(NSTimeInterval(0.25)) {
			var frame = CGRectMake(0, 0, width, CentralUIDesign.informationPanelHeight)
			for panel in self.stack {
				panel.frame = frame
				frame.origin.y += CentralUIDesign.informationPanelHeight
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





public struct Alert {
	let icon: UIImage
	let message: String
	let actionArg: Any?
	let action: ((Any?) -> Void)?
}





class AlertPanel: UIView, Dependent, FragmentDelegate {

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

	var controller: UIViewController! {
		return nil
	}

	func onAction(action: String, args: String?) {
		if action == "close" {
			stack?.hidePanelAnimated(self)
		}
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
			if let action = ui.alert?.action {
				action(ui.alert!.actionArg)
			}
		}
		stack.hidePanelAnimated(self)
	}

	// MARK: - Dependent

	var dependency: DependencyResolver! {
		didSet {
			ui.dependency = dependency
		}
	}

}



public class AlertUi: Fragment {

	var alert: Alert? {
		return model as? Alert
	}

	let icon = ImageElement()

	public convenience init() {
		self.init(forModelType: Alert.self)
	}

	public override func onModelChanged() {
		icon.image = alert?.icon
	}

}


