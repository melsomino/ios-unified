//
//  AppDelegate.swift
//  Layouts
//
//  Created by Michael Vlasov on 15.06.16.
//  Copyright © 2016 Michael Vlasov. All rights reserved.
//

import UIKit
import Unified

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CentralUiDependent {

	var window: UIWindow?
	var dependency: DependencyResolver!


	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {
		dependency = DependencyContainer {
			container in
			container.createDefaultRepository()
			container.createDefaultCentralUi()
		}

		window = UIWindow(frame: UIScreen.mainScreen().bounds)
		window!.rootViewController = centralUi.rootController
		window!.makeKeyAndVisible()

		centralUi.addMenuItem("Layouts", title: "Layouts", icon: nil, action: .Content({ self.createLayoutsController() }))
		centralUi.selectedMenuItem = centralUi.menuItemAtIndex(0)
		return true
	}

	func createLayoutsController() -> ViewController {
		let controller = ViewController()
		controller.dependency = dependency
		return controller
	}



}

