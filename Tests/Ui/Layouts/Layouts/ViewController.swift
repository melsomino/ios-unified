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




class TestUi: Ui<TestModel> {
	let icon = LayoutView()
	let text = LayoutText()
	let details = LayoutText()
	let warning = LayoutText()
	let footer = LayoutText()

	override init() {
		super.init()
	}

	override func onModelChanged() {
		text.text = model?.text
		details.text = model?.details
		warning.text = model?.warning
		footer.text = model?.footer
	}
}





class ViewController: UIViewController, Dependent {

	override func viewDidLoad() {
		super.viewDidLoad()

		createComponents()

		ui = TestUi()
		ui.dependency = dependency
		ui.container = view
		ui.model = createTestModel()
	}


	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		ui.performLayout()
	}


	var dependency: DependencyResolver!
	var ui: TestUi!


	private func createComponents() {
		let components = DependencyContainer()
		components.createDefaultRepository()
		components.required(RepositoryDependency).devServerUrl = NSURL(string: "ws://localhost:8080/events")
		dependency = components
	}

	private func createTestModel() -> TestModel {
		return TestModel(text: "Text",
			details: "Details Details Details Details Details Details Details Details Details Details Details Details Details Details Details Details Details",
			warning: "Warning",
			footer: "Footer")
	}

}

