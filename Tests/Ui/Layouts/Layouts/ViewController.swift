//
//  ViewController.swift
//  Layouts
//
//  Created by Michael Vlasov on 15.06.16.
//  Copyright © 2016 Michael Vlasov. All rights reserved.
//

import UIKit
import Unified




struct TestModel {
	let text: String
	let details: String
	let warning: String
	let footer: String
}


class TestUi: ModelUi<TestModel> {

}

class ViewController: UIViewController, Dependent {

	static func create(dependency: DependencyResolver) -> UIViewController {
		let controller = ViewController()
		dependency.resolve(controller)
		let nav = UINavigationController(rootViewController: controller)
		return nav
	}

	private var scroller: UIScrollView!

	override func viewDidLoad() {
		super.viewDidLoad()

		view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
		view.backgroundColor = UIColor.whiteColor()

		scroller = UIScrollView(frame: view.bounds)
		scroller.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
		view.addSubview(scroller)

		ui.container = scroller
		ui.model = createTestModel()

		navigationItem.title = "UI Layouts"

	}

	override func shouldAutorotate() -> Bool {
		return true
	}


	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		ui.performLayout()
	}


	var dependency: DependencyResolver! {
		didSet {
			dependency?.resolve(ui)
		}
	}
	var ui = ModelUi<TestModel>()


	private func createTestModel() -> TestModel {
		return TestModel(text: "Text",
			details: "Details Details Details Details Details Details Details Details Details Details Details Details Details Details Details Details Details",
			warning: "Warning",
			footer: "Footer")
	}

}

