//
// Created by Michael Vlasov on 30.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class MainMenuSideController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {

	public static func show(centralUi: CentralUi) {
		let storyboard = UIStoryboard(name: "MainMenu", bundle: NSBundle(forClass: DefaultCentralUi.self))
		let sideController = storyboard.instantiateViewControllerWithIdentifier("MainMenuSideController") as! MainMenuSideController
		sideController.setCentralUi(centralUi)
		sideController.showAnimated()
	}


	public func setCentralUi(centralUi: CentralUi) {
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


	@IBAction func openSettings(sender: AnyObject) {
	}


	@IBAction func closeMenu(sender: AnyObject) {
		hideAnimated(nil)
	}


	// MARK: - ViewController


	public override func viewDidLoad() {
		super.viewDidLoad()
		MainMenuItemCell.registerCellTypes(tableView)
		logonImage.image = centralUi.accountIcon
		logonLabel.text = centralUi.accountTitle
		tableView.backgroundColor = menuContainer.backgroundColor
		tableView.separatorStyle = .None
		tableView.scrollEnabled = false

		rightShadowView.backgroundColor = UIColor.clearColor()

		let gradient: CAGradientLayer = CAGradientLayer()
		gradient.frame = rightShadowView.bounds
		let black = UIColor.blackColor()
		gradient.colors = [
			black.colorWithAlphaComponent(0).CGColor,
			black.colorWithAlphaComponent(0.2).CGColor,
			black.colorWithAlphaComponent(0.8).CGColor]
		gradient.startPoint = CGPointMake(0, 0.5)
		gradient.endPoint = CGPointMake(1, 0.5)
		rightShadowView.layer.addSublayer(gradient)

		swipeRecognizer = UIPanGestureRecognizer()
		swipeRecognizer.delegate = self
		swipeRecognizer.maximumNumberOfTouches = 1
		swipeRecognizer.addTarget(self, action: #selector(handleSwipeGesture))
		view.addGestureRecognizer(swipeRecognizer)
	}


	public override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		tableView.scrollEnabled = tableView.bounds.height < tableView.rowHeight * CGFloat(centralUi.menuItemCount)
	}


	// MARK: - Swipe Gesture Delegate


	public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
		let velocity = swipeRecognizer.velocityInView(centralUi.rootController.view)
		let isHorizontalPan = abs(velocity.x) > abs(velocity.y)
		return isHorizontalPan
	}



	public func handleSwipeGesture() {
		let rootController = centralUi.rootController
		let rootBounds = rootController.view.bounds
		let menuWidth = MainMenuSideController.menuWidth
		let location = swipeRecognizer.locationInView(centralUi.rootController.view)
		switch swipeRecognizer.state {
			case .Possible:
				break

			case .Began:
				swipeStarted = true
				swipeStartLocation = location

			case .Changed:
				let offset = min(0, max(-menuWidth, location.x - swipeStartLocation.x))
				view.frame = CGRectOffset(rootBounds, offset, 0)
				centralUi.contentContainer.frame = CGRectOffset(rootBounds, menuWidth + offset, 0)
				break

			default:
				guard swipeStarted else {
					break
				}
				let shouldHide = swipeRecognizer.velocityInView(centralUi.rootController.view).x < 0
				swipeStarted = false

				view.removeGestureRecognizer(swipeRecognizer)
				view.addGestureRecognizer(swipeRecognizer)

				if shouldHide {
					hideAnimated(nil)
				}
				else {
					UIView.animateWithDuration(NSTimeInterval(0.25)) {
						self.view.frame = rootBounds
						self.centralUi.contentContainer.frame = CGRectOffset(rootBounds, menuWidth, 0)
					}
				}
				break
		}
	}


	// MARK: - Table Data Source & Delegate


	public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return centralUi.menuItemCount
	}


	public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return MainMenuItemCell.cellForItem(centralUi.menuItemAtIndex(indexPath.row), selected: indexPath.row == centralUi.selectedMenuItem?.index ?? -1, tableView: tableView, indexPath: indexPath)
	}


	public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		centralUi.selectedMenuItem = centralUi.menuItemAtIndex(indexPath.row)
		hideAnimated(nil)
	}


	// MARK: - Internals


	private var centralUi: CentralUi!

	private var swipeRecognizer: UIPanGestureRecognizer!
	private var swipeStartLocation = CGPointZero
	private var swipeStarted = false

	private static let menuWidth = CGFloat(270)

	func showAnimated() {
		let rootController = centralUi.rootController
		let rootBounds = rootController.view.bounds
		let menuWidth = MainMenuSideController.menuWidth

		rootController.addChildViewController(self)
		view.frame = CGRectOffset(rootBounds, -menuWidth, 0)
		menuContainer.frame = CGRectMake(0, 0, menuWidth, rootBounds.height)
		closeMenuContainer.frame = CGRectMake(menuWidth, 0, rootBounds.width, rootBounds.height)
		rootController.view.addSubview(self.view)
		UIView.animateWithDuration(NSTimeInterval(0.25),
			animations: {
				self.view.frame = rootBounds
				self.centralUi.contentContainer.frame = CGRectOffset(rootBounds, menuWidth, 0)
			},
			completion: {
				finished in
				self.didMoveToParentViewController(rootController)
			})
	}

	func hideAnimated(completion: ((Bool) -> Void)?) {
		let rootController = centralUi.rootController
		let rootBounds = rootController.view.bounds

		willMoveToParentViewController(nil)
		UIView.animateWithDuration(NSTimeInterval(0.25),
			animations: {
				self.view.frame = CGRectOffset(rootBounds, -MainMenuSideController.menuWidth, 0)
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
