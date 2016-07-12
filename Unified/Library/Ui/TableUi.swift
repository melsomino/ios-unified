//
// Created by Власов М.Ю. on 15.06.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import UIKit





public class TableUi: NSObject, RepositoryDependent, RepositoryListener, UITableViewDataSource, UITableViewDelegate {


	public var tableView: UITableView! {
		didSet {
			if let prev = oldValue {
				prev.dataSource = nil
				prev.delegate = nil
			}
			if let current = tableView {
				current.delegate = self
				current.dataSource = self
				for registration in registrations {
					current.registerClass(TableCellUi.self, forCellReuseIdentifier: registration.cellReuseId)
				}
			}
		}
	}


	public func setModels(models: [Any]) {
		self.models = models
		tableView?.reloadData()
	}

	public func createController() -> UIViewController {
		let controller = TableUiController()
		controller.ui = self
		return controller
	}

	// MARK: - Dependency


	public var dependency: DependencyResolver! {
		didSet {
			repository.addListener(self)
		}
	}


	// MARK: - Repository Listener


	public func repositoryChanged(repository: Repository) {
		tableView.reloadData()
	}


	// MARK: - Table View DataSource and Delegate


	public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return models.count
	}


	public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let model = models[indexPath.row]
		let registration = requiredRegistration(model)
		let cell = tableView.dequeueReusableCellWithIdentifier(registration.cellReuseId, forIndexPath: indexPath) as! TableCellUi
		if cell.ui == nil {
			cell.ui = registration.createUi(dependency)
			cell.ui.container = cell.contentView
		}
		cell.ui.model = model
		return cell
	}


	public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		let model = models[indexPath.row]
		return requiredRegistration(model).heightFor(model, inWidth: tableView.bounds.width)
	}


	// MARK: - Internals


	private var registrations = [ModelUiRegistration]()
	private var models: [Any]!


	private func requiredRegistration(model: Any) -> ModelUiRegistration {
		for registration in registrations {
			if registration.supports(model) {
				return registration
			}
		}

		let registration = ModelUiRegistration(dependency: dependency, forModelType: model.dynamicType)
		registrations.append(registration)
		tableView?.registerClass(TableCellUi.self, forCellReuseIdentifier: registration.cellReuseId)
		return registration
	}

}





class TableCellUi: UITableViewCell {

	override func layoutSubviews() {
		super.layoutSubviews()
		ui?.performLayout(inBounds: contentView.bounds.size)
	}

	var ui: Ui!
}





private class ModelUiRegistration {
	var uiFactory: UiFactory!
	let heightCalculator: Ui
	let cellReuseId: String
	let modelType: Any.Type


	init(dependency: DependencyResolver, forModelType modelType: Any.Type) {
		self.modelType = modelType
		cellReuseId = String(reflecting: modelType)
		heightCalculator = Ui(forModelType: modelType)
		dependency.resolve(heightCalculator)
	}


	func supports(model: Any) -> Bool {
		return model.dynamicType == modelType
	}


	func createUi(dependency: DependencyResolver) -> Ui {
		let ui = Ui(forModelType: modelType)
		dependency.resolve(ui)
		return ui
	}


	func heightFor(model: Any, inWidth width: CGFloat) -> CGFloat {
		heightCalculator.model = model
		heightCalculator.performLayout(inWidth: width)
		return heightCalculator.frame.height
	}

}





class TableUiController: UIViewController {
	weak var ui: TableUi!

	override func viewDidLoad() {
		super.viewDidLoad()
		let tableView = UITableView(frame: view.bounds)
		tableView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
		view.addSubview(tableView)
		ui.tableView = tableView
	}

}





