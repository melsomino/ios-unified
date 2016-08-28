//
//  AppDelegate.swift
//  Layouts
//
//  Created by Michael Vlasov on 15.06.16.
//  Copyright © 2016 Michael Vlasov. All rights reserved.
//

import UIKit
import Unified

struct Header {
	let title: String
	let totalCount: String
}

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
	return NSCalendar.currentCalendar().dateFromComponents(components)!
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




@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CentralUIDependent, RepositoryDependent {


	var window: UIWindow?
	var dependency: DependencyResolver!


	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {

		dependency = DependencyContainer {
			container in
			container.createDefaultThreading()
			container.createDefaultRepository()
			container.createDefaultCentralUI()
		}

		repository.devServerUrl = RepositoryDefaultDevServerUrl

		let fragment = AlbumsFragment(dependency: dependency)

		window = UIWindow(frame: UIScreen.mainScreen().bounds)
		window!.rootViewController = centralUI.rootController
		window!.makeKeyAndVisible()

		centralUI.addMenuItem("Layouts", title: "Layouts", icon: nil, action: .setContent({ dependency in fragment.createController() }))
		centralUI.selectedMenuItem = centralUI.menuItemAtIndex(0)
		return true
	}


}


class AlbumsFragment: TableFragment {
	override func loadModels(execution: Execution, inout models: [Any]) throws {
		models.append(Header(title: "Требования ФНС", totalCount: "20"))
		models.append(Header(title: "Задачи", totalCount: "21"))
//		models = join(KissDestroyer, children: KissDestroyer.tracks)
	}

}


