//
//  AppDelegate.swift
//  Layouts
//
//  Created by Michael Vlasov on 15.06.16.
//  Copyright © 2016 Michael Vlasov. All rights reserved.
//

import UIKit
import Unified


struct AlbumTrack {
	let title: String
	let duration: NSTimeInterval
}

struct Album {
	let artist: String
	let title: String
	let issued: NSDate
	let tracks: [AlbumTrack]
}


func makeDate(d: Int, _ m: Int, _ y: Int) -> NSDate {
	let components = NSDateComponents()
	components.day = d
	components.month = m
	components.year = y
	return components.date!
}


func makeDuration(m: Int, _ s: Int) -> NSTimeInterval {
	return NSTimeInterval(m) + NSTimeInterval(s) / 60
}


let KissDestroyer = Album(artist: "Kiss", title: "Destroyer", issued: makeDate(5, 3, 1976), tracks: [
	AlbumTrack(title: "Detroit Rock City", duration: makeDuration(5, 17)),
	AlbumTrack(title: "King of the Night Time World", duration: makeDuration(3, 19)),
	AlbumTrack(title: "God of Thunder", duration: makeDuration(4, 13)),
	AlbumTrack(title: "Great Expectations", duration: makeDuration(4, 24)),
	AlbumTrack(title: "Flaming Youth", duration: makeDuration(3, 00)),
	AlbumTrack(title: "Sweet Pain", duration: makeDuration(3, 20)),
	AlbumTrack(title: "Shout It Out Loud", duration: makeDuration(2, 49)),
	AlbumTrack(title: "Beth", duration: makeDuration(2, 45)),
	AlbumTrack(title: "Do You Love Me?", duration: makeDuration(4, 57))
])



func join<Child>(head: Any, children: [Child]) -> [Any] {
	var joined = [Any]()
	joined.append(head)
	for child in children {
		joined.append(child)
	}
	return joined
}

class MyClass {
	let a = "A"

	 func printA() {
		 print(a)
	 }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CentralUiDependent, RepositoryDependent {

	var window: UIWindow?
	var dependency: DependencyResolver!


	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {


		dependency = DependencyContainer {
			container in
			container.createDefaultRepository()
			container.createDefaultCentralUi()
		}

		repository.devServerUrl = RepositoryDefaultDevServerUrl


		let m  = MyClass()
		let printA: () -> Void
		printA = m.printA
		printA()


		let ui = TableUi()
		dependency.resolve(ui)
		ui.setModels(join(KissDestroyer, children: KissDestroyer.tracks))

		window = UIWindow(frame: UIScreen.mainScreen().bounds)
		window!.rootViewController = centralUi.rootController
		window!.makeKeyAndVisible()

		centralUi.addMenuItem("Layouts", title: "Layouts", icon: nil, action: .SetContent({ dependency in ui.createController() }))
		centralUi.selectedMenuItem = centralUi.menuItemAtIndex(0)
		return true
	}
}


