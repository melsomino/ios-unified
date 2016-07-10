//
//  AppDelegate.swift
//  Layouts
//
//  Created by Michael Vlasov on 15.06.16.
//  Copyright © 2016 Michael Vlasov. All rights reserved.
//

import UIKit
import Unified





struct Model1 {
	let a: String
	let b: Int
	let c: Bool
	let d: NSDate
}





@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CentralUiDependent, RepositoryDependent {

	var window: UIWindow?
	var dependency: DependencyResolver!


	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {
		let m = Model1(a: "A", b: 12, c: true, d: NSDate())
		var b = UiBinding()
		let e = b.parse("a={a}, b={b}, c={c}, d={d}")
		b.setModel(m)
		print(b.evaluateExpression(e))



		dependency = DependencyContainer {
			container in
			container.createDefaultRepository()
			container.createDefaultCentralUi()
		}

		repository.devServerUrl = RepositoryDefaultDevServerUrl

		window = UIWindow(frame: UIScreen.mainScreen().bounds)
		window!.rootViewController = centralUi.rootController
		window!.makeKeyAndVisible()

		centralUi.addMenuItem("Layouts", title: "Layouts", icon: nil, action: .SetContent({ ViewController.create($0) }))
		centralUi.selectedMenuItem = centralUi.menuItemAtIndex(0)
		return true
	}


}

