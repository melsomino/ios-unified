//
// Created by Michael Vlasov on 11.12.16.
// Copyright (c) 2016 Melsomino. All rights reserved.
//

import Foundation
import UIKit
import Unified


class HtmlUrlViewModel {
	let url: String
	init(url: String) {
		self.url = url
	}
}

class HtmlCommentViewModel {
	let message: String
	init(message: String) {
		self.message = message
	}
}


class HtmlContentViewModel {

}

class HtmlContentFragment: ListFragment {

	static func createRootController(dependency: DependencyResolver) -> UIViewController {
		let fragment = HtmlContentFragment(dependency: dependency)
		fragment.model = HtmlContentViewModel()
		return UINavigationController(rootViewController: fragment.createController())
	}



	override func loadPortion(items: inout [AnyObject], from: Any?, async: Execution) throws -> Any? {
		items.append(HtmlUrlViewModel(url: "https://habrahabr.ru/post/317328"))
		for i in 0 ..< 100 {
			items.append(HtmlCommentViewModel(message: "Comment \(i + 1)"))
		}
		return nil
	}

}
