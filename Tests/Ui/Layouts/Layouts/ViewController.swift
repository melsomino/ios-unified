//
//  ViewController.swift
//  Layouts
//
//  Created by Michael Vlasov on 15.06.16.
//  Copyright © 2016 Melsomino. All rights reserved.
//

import UIKit
import Unified

private let uiLayouts = [
	"Layouts.TestLayout": [
		"vertical margin=20 marginTop=40 spacing=8 along=leading",
		"    horizontal spacing=8",
		"        view #icon align=center size=55 fixedSize=true cornerRadius=8 background=green scale=aspect-fit source=TestImage",
		"        vertical along=leading",
		"            layered",
		"                view background=red cornerRadius=3",
		"                label #text color=yellow margin=(8 4)",
		"            label #details",
		"    label #warning font=('Helvetica Neue' 24) color=red",
		"    label #footer font=13 color=aaa",
	]
]


protocol UiRepository {
	func compileLayouts(source: String)
	func createLayoutRootFor(layout: Layout) -> LayoutItem
}

let UiRepositoryDependency = Dependency<UiRepository>()

extension DependencyResolver {
	var uiRepository: UiRepository {
		return required(UiRespositoryDependency)
	}
	var optionalUiRepository: UiRepository {
		return optional(UiRespositoryDependency)
	}
}

class DefaultUiRepository: UiRepository {
	private var layoutFactoryByClassName = [String:LayoutItemFactory]()

	func compileLayouts(source: String) {
		let lines = source.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet()).filter{!$0.isEmpty}
	}

	func createLayoutRootFor(layout: Layout) -> LayoutItem {
		let className = String(NSStringFromClass(layout.dynamicType))
		guard let factory = layoutFactoryByClassName[className] else {
			fatalError("UiRepository does not contains layout definition for: \(className)")
		}
		return factory.createItem()
	}
}


class UiLayout<Model>: LayoutWithModel<Model> {



}





class TestLayout: UiLayout<Model1> {

}





class ViewController: UIViewController {


	override func viewDidLoad() {
		super.viewDidLoad()
		layout = Layout1(inSuperview: view)
		layout.setModel(Model1(text: "Text", details: "Details Details Details Details Details Details Details Details Details Details Details Details Details Details Details Details Details", warning: "Warning", footer: "Footer"))

		let test = TestLayout()
	}


	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		layout.performLayoutForWidth(view.bounds.width)
	}

	private var layout: Layout1!
}





struct Model1 {
	let text: String
	let details: String
	let warning: String
	let footer: String
}





class Layout1: LayoutWithModel<Model1> {

	let text = LayoutLabel()
	let details = LayoutLabel()
	let warning = LayoutLabel()
	let footer = LayoutLabel()

	required init(inSuperview superview: UIView?) {
		super.init(inSuperview: superview)
	}


	override func createRoot() -> LayoutItem {
		let factory = try! LayoutItemFactory.parse(markup)
		return factory.createWith(self)
	}


	override func reflectLayout() {
		text.text = model.text
		details.text = model.details
		warning.text = model.warning
		footer.text = model.footer
	}

	let markup = [
		"vertical margin=20 marginTop=40 spacing=8 along=leading",
		"    horizontal spacing=8",
		"        view #icon align=center size=55 fixedSize=true cornerRadius=8 background=green scale=aspect-fit source=TestImage",
		"        vertical along=leading",
		"            layered",
		"                view background=red cornerRadius=3",
		"                label #text color=yellow margin=(8 4)",
		"            label #details",
		"    label #warning font=('Helvetica Neue' 24) color=red",
		"    label #footer font=13 color=aaa",
	]
}
