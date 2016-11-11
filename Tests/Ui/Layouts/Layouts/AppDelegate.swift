//
//  AppDelegate.swift
//  Layouts
//
//  Created by Michael Vlasov on 15.06.16.
//  Copyright © 2016 Michael Vlasov. All rights reserved.
//

import UIKit
import Unified





class Header {
	let title: String?
	let totalCount: String
	init(title: String?, totalCount: String) {
		self.title = title
		self.totalCount = totalCount
	}
}





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









func test_html() {
	let text = HtmlParser.plainText(from: "<p>Параграф <a href='sdsfds'>fdsfds</a> <b>1</b></p><p>Параграф<br><i>2</i></p>")
	print(text)
}





@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CentralUIDependent, RepositoryDependent {


	var window: UIWindow?
	var dependency: DependencyResolver!


	public func repositoryChanged(_ repository: Repository) {
	}



	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

		Fragment.setup()

		test_html()

		dependency = DependencyContainer {
			container in
			container.createDefaultThreading()
			container.createDefaultRepository()
			container.createDefaultCentralUI()
		}

		repository.devServerUrl = RepositoryDefaultDevServerUrl

		let fragment = AlbumsFragment(dependency: dependency)

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





class AlbumsFragment: ListFragment {



	override func loadModels(_ execution: Execution, models: inout [AnyObject]) throws {
		models.append(Header(title: "Требования ФНС", totalCount: "20"))
//		models.append(Header(title: "Задачи", totalCount: "21"))
//		models = join(KissDestroyer, children: KissDestroyer.tracks)
	}



	override func onControllerAttached() {
		super.onControllerAttached()
		controller.navigationItem.title = "Layouts"
		controller.navigationItem.leftBarButtonItem = centralUI.createMenuIntegrationBarButtonItem()
	}

}


