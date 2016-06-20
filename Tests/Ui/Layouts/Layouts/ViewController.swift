//
//  ViewController.swift
//  Layouts
//
//  Created by Michael Vlasov on 15.06.16.
//  Copyright © 2016 Melsomino. All rights reserved.
//

import UIKit
import Unified

public class Ui<Model>: LayoutWithModel<Model> {
	public let dependency: DependencyResolver

	init(inSuperview superview: UIView?, dependency: DependencyResolver) {
		self.dependency = dependency
		super.init(inSuperview: superview)
	}

	public override func createRoot() -> LayoutItem {
		return try! dependency.repository.createLayoutFor(self)
	}

}


struct TestModel {
	let text: String
	let details: String
	let warning: String
	let footer: String
}




class TestUi: Ui<TestModel> {
	let text = LayoutLabel()
	let details = LayoutLabel()
	let warning = LayoutLabel()
	let footer = LayoutLabel()

	override init(inSuperview superview: UIView?, dependency: DependencyResolver) {
		super.init(inSuperview: superview, dependency: dependency)
	}


	override func reflectLayout() {
		text.text = model.text
		details.text = model.details
		warning.text = model.warning
		footer.text = model.footer
	}
}





class ViewController: UIViewController {


	override func viewDidLoad() {
		super.viewDidLoad()

		dependency.createDefaultRepository()

		ui = TestUi(inSuperview: view, dependency: dependency)
		ui.setModel(TestModel(text: "Text",
			details: "Details Details Details Details Details Details Details Details Details Details Details Details Details Details Details Details Details",
			warning: "Warning",
			footer: "Footer"))
	}


	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		ui.performLayoutForWidth(view.bounds.width)
	}

	private var dependency = DependencyContainer()
	private var ui: TestUi!
}

