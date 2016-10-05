//
// Created by Michael Vlasov on 10.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit



open class AlertStack: Dependent {


	open var dependency: DependencyResolver!

	public init() {
	}



	open func pushInContainer(_ container: UIView, alert: CentralUIAlert, message: String, icon: UIImage?, actionArg: Any?, action: ((Any?) -> Void)?) {
		var icon = icon
		if icon == nil {
			switch alert {
				case .error:
					icon = CentralUIDesign.alertErrorIcon
				case .warning:
					icon = CentralUIDesign.alertWarningIcon
				case .success, .information:
					icon = CentralUIDesign.alertInformationIcon
			}
		}
		let newPanel = AlertPanel(frame: CGRect(x: 0, y: -CentralUIDesign.informationPanelHeight, width: container.bounds.width, height: CentralUIDesign.informationPanelHeight))
		newPanel.dependency = dependency
		newPanel.stack = self
		newPanel.ui.model = Alert(icon: icon!, message: message, actionArg: actionArg, action: action)

		stack.insert(newPanel, at: 0)
		container.addSubview(newPanel)

		let hideTime = DispatchTime.now() + Double(Int64(NSEC_PER_SEC * 3)) / Double(NSEC_PER_SEC)
		weak var weakPanel = newPanel
		DispatchQueue.main.asyncAfter(deadline: hideTime) {
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

		UIView.animate(withDuration: TimeInterval(0.25), animations: {
			var frame = CGRect(x: 0, y: 0, width: width, height: CentralUIDesign.informationPanelHeight)
			for panel in self.stack {
				panel.frame = frame
				frame.origin.y += CentralUIDesign.informationPanelHeight
			}
		}) 
	}



	func hidePanelAnimated(_ panel: AlertPanel) {
		guard stack.contains(panel) else {
			return
		}
		UIView.animate(withDuration: TimeInterval(0.25),
			animations: {
				panel.alpha = 0
			},
			completion: {
				finished in
				if let index = self.stack.index(of: panel) {
					self.stack.remove(at: index)
				}
				panel.removeFromSuperview()
				self.relocatePanelsAnimated()
			})
	}


	fileprivate var stack = [AlertPanel]()
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
		isUserInteractionEnabled = true
		autoresizingMask = [.flexibleWidth]
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

	func onAction(_ action: String, args: String?) {
		if action == "close" {
			stack?.hidePanelAnimated(self)
		}
	}



	func layoutChanged(forFragment fragment: Fragment) {
	}



	@objc func tapOnPanelRecognized(_ sender: UITapGestureRecognizer) {
		guard sender.state == .ended else {
			return
		}
		guard let stack = stack else {
			return
		}
		let location = sender.location(in: self)
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



open class AlertUi: Fragment {

	var alert: Alert? {
		return model as? Alert
	}

	let icon = ImageElement()

	public convenience init() {
		self.init(forModelType: Alert.self)
	}



	open override func onModelChanged() {
		icon.image = alert?.icon
	}

}


