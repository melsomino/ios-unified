//
// Created by Michael Vlasov on 30.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

open class CentralUISideController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {

	open static func show(_ centralUi: CentralUI) {
		let storyboard = UIStoryboard(name: "MainMenu", bundle: Bundle(for: DefaultCentralUI.self))
		let sideController = storyboard.instantiateViewController(withIdentifier: "MainMenuSideController") as! CentralUISideController
		sideController.setCentralUi(centralUi)
		sideController.showAnimated()
	}


	open func setCentralUi(_ centralUi: CentralUI) {
		self.centralUi = centralUi
	}


	// MARK: - UI Elements


	@IBOutlet weak var menuContainer: UIView!
	@IBOutlet weak var closeMenuContainer: UIView!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var logonImage: UIImageView!
	@IBOutlet weak var logonLabel: UILabel!
	@IBOutlet weak var logonSeparator: UIView!
	@IBOutlet weak var rightShadowView: UIView!


	// MARK: - UI Actions


	@IBAction func openSettings(_ sender: AnyObject) {
		if let settings = centralUi.settingsAction {
			hideAnimated(nil)
			centralUi.execute(settings)
		}
	}


	@IBAction func closeMenu(_ sender: AnyObject) {
		hideAnimated(nil)
	}


	// MARK: - ViewController


	open override func viewDidLoad() {
		super.viewDidLoad()
		MainMenuItemCell.registerCellTypes(tableView)
		logonImage.image = centralUi.accountIcon
		logonLabel.text = centralUi.accountTitle
		tableView.backgroundColor = menuContainer.backgroundColor
		tableView.separatorStyle = .none
		tableView.isScrollEnabled = false

		rightShadowView.backgroundColor = UIColor.clear

		let gradient: CAGradientLayer = CAGradientLayer()
		gradient.frame = rightShadowView.bounds
		let black = UIColor.black
		gradient.colors = [
			black.withAlphaComponent(0).cgColor,
			black.withAlphaComponent(0.2).cgColor,
			black.withAlphaComponent(0.8).cgColor]
		gradient.startPoint = CGPoint(x: 0, y: 0.5)
		gradient.endPoint = CGPoint(x: 1, y: 0.5)
		rightShadowView.layer.addSublayer(gradient)

		swipeRecognizer = UIPanGestureRecognizer()
		swipeRecognizer.delegate = self
		swipeRecognizer.maximumNumberOfTouches = 1
		swipeRecognizer.addTarget(self, action: #selector(handleSwipeGesture))
		view.addGestureRecognizer(swipeRecognizer)
	}


	open override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		tableView.isScrollEnabled = tableView.bounds.height < tableView.rowHeight * CGFloat(centralUi.menuItemCount)
	}


	// MARK: - Swipe Gesture Delegate


	open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		let velocity = swipeRecognizer.velocity(in: centralUi.rootController.view)
		let isHorizontalPan = abs(velocity.x) > abs(velocity.y)
		return isHorizontalPan
	}



	open func handleSwipeGesture() {
		let rootController = centralUi.rootController
		let rootBounds = rootController.view.bounds
		let menuWidth = CentralUISideController.menuWidth
		let location = swipeRecognizer.location(in: centralUi.rootController.view)
		switch swipeRecognizer.state {
			case .possible:
				break

			case .began:
				swipeStarted = true
				swipeStartLocation = location

			case .changed:
				let offset = min(0, max(-menuWidth, location.x - swipeStartLocation.x))
				view.frame = rootBounds.offsetBy(dx: offset, dy: 0)
				centralUi.contentContainer.frame = rootBounds.offsetBy(dx: menuWidth + offset, dy: 0)
				break

			default:
				guard swipeStarted else {
					break
				}
				let shouldHide = swipeRecognizer.velocity(in: centralUi.rootController.view).x < 0
				swipeStarted = false

				view.removeGestureRecognizer(swipeRecognizer)
				view.addGestureRecognizer(swipeRecognizer)

				if shouldHide {
					hideAnimated(nil)
				}
				else {
					UIView.animate(withDuration: TimeInterval(0.25), animations: {
						self.view.frame = rootBounds
						self.centralUi.contentContainer.frame = rootBounds.offsetBy(dx: menuWidth, dy: 0)
					}) 
				}
				break
		}
	}


	// MARK: - Table Data Source & Delegate


	open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return centralUi.menuItemCount
	}


	open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return MainMenuItemCell.cellForItem(centralUi.menuItemAtIndex(indexPath.row), selected: indexPath.row == centralUi.selectedMenuItem?.index ?? -1, tableView: tableView, indexPath: indexPath)
	}


	open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		centralUi.selectedMenuItem = centralUi.menuItemAtIndex(indexPath.row)
		hideAnimated(nil)
	}


	// MARK: - Internals


	private var centralUi: CentralUI!

	private var swipeRecognizer: UIPanGestureRecognizer!
	private var swipeStartLocation = CGPoint.zero
	private var swipeStarted = false

	private static let menuWidth = CGFloat(270)

	func showAnimated() {
		let rootController = centralUi.rootController
		let rootBounds = rootController.view.bounds
		let menuWidth = CentralUISideController.menuWidth

		rootController.addChildViewController(self)
		view.frame = rootBounds.offsetBy(dx: -menuWidth, dy: 0)
		menuContainer.frame = CGRect(x: 0, y: 0, width: menuWidth, height: rootBounds.height)
		closeMenuContainer.frame = CGRect(x: menuWidth, y: 0, width: rootBounds.width, height: rootBounds.height)
		rootController.view.addSubview(self.view)
		UIView.animate(withDuration: TimeInterval(0.25),
			animations: {
				self.view.frame = rootBounds
				self.centralUi.contentContainer.frame = rootBounds.offsetBy(dx: menuWidth, dy: 0)
			},
			completion: {
				finished in
				self.didMove(toParentViewController: rootController)
			})
	}

	func hideAnimated(_ completion: ((Bool) -> Void)?) {
		let rootController = centralUi.rootController
		let rootBounds = rootController.view.bounds

		willMove(toParentViewController: nil)
		UIView.animate(withDuration: TimeInterval(0.25),
			animations: {
				self.view.frame = rootBounds.offsetBy(dx: -CentralUISideController.menuWidth, dy: 0)
				self.centralUi.contentContainer.frame = rootBounds
			},
			completion: {
				finished in
				self.view.removeFromSuperview()
				self.removeFromParentViewController()
				completion?(finished)
			})
	}

}
