//
//  AppDelegate.swift
//  Layouts
//
//  Created by Michael Vlasov on 15.06.16.
//  Copyright © 2016 Michael Vlasov. All rights reserved.
//

import UIKit
import Unified



class AlbumTrack {
	let title: String
	let duration: TimeInterval
	init(title: String, duration: TimeInterval) {
		self.title = title
		self.duration = duration
	}
}



class Album {
	let artist: String
	let title: String
	let issued: Date
	let tracks: [AlbumTrack]
	init(artist: String, title: String, issued: Date, tracks: [AlbumTrack]) {
		self.artist = artist
		self.title = title
		self.issued = issued
		self.tracks = tracks
	}

}



func makeDate(_ d: Int, _ m: Int, _ y: Int) -> Date {
	var components = DateComponents()
	components.day = d
	components.month = m
	components.year = y
	return Calendar.current.date(from: components)!
}



func makeDuration(_ m: Int, _ s: Int) -> TimeInterval {
	return TimeInterval(m) + TimeInterval(s) / 60
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


	public func repositoryChanged(_ repository: Repository) {
	}



	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

		UnifiedRuntime.setup()

		dependency = DependencyContainer {
			container in
			container.createDefaultThreading()
			container.createDefaultRepository()
			container.createDefaultCentralUI()
		}

		repository.devServerUrl = RepositoryDefaultDevServerUrl

		let fragment = AlbumsFragment(dependency: dependency)
		fragment.model = AlbumsViewModel(artist: "Kiss")

		window = UIWindow(frame: UIScreen.main.bounds)
		window!.rootViewController = centralUI.rootController
		window!.makeKeyAndVisible()

		centralUI.addMenuItem("Layouts", title: "Layouts", icon: nil, action: .setContent({
			dependency in
			UINavigationController(rootViewController: fragment.createController())
		}))
		centralUI.selectedMenuItem = centralUI.menuItemAtIndex(0)
		return true
	}


}

class AlbumsViewModel {
	public var artist = ""
	public init(artist: String) {
		self.artist = artist
	}
}


class AlbumsFragment: ListFragment {

	override func loadPortion(items: inout [AnyObject], from: Any?, async: Execution) throws -> Any? {
		items.append(KissDestroyer)
		for track in KissDestroyer.tracks {
			items.append(track)
		}
		return nil
	}



	override func onInit() {
		super.onInit()
		controller.navigationItem.title = "Albums"
		controller.navigationItem.leftBarButtonItem = centralUI.createMenuIntegrationBarButtonItem()
	}

}


