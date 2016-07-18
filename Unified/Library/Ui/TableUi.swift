//
// Created by Власов М.Ю. on 15.06.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import UIKit




public class TableUi: NSObject, RepositoryDependent, RepositoryListener, UITableViewDataSource, UITableViewDelegate {

	public let loadModels: (Execution, inout [Any]) throws -> Void
	public var syncModels: (() throws -> Void)?

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


	public func createController() -> UIViewController {
		let controller = TableUiController()
		controller.ui = self
		return controller
	}


	public func ensureRegistration(forModelType modelType: Any.Type) -> ModelUiRegistration {
		for registration in registrations {
			if registration.modelType == modelType {
				return registration
			}
		}

		let registration = ModelUiRegistration(forModelType: modelType, layoutCache: layoutCache, dependency: dependency)
		registrations.append(registration)
		tableView?.registerClass(TableCellUi.self, forCellReuseIdentifier: registration.cellReuseId)
		return registration
	}


	public init(dependency: DependencyResolver, loadModels: (Execution, inout [Any]) throws -> Void) {
		self.loadModels = loadModels
		super.init()
		dependency.resolve(self)
	}


	public final func startLoad() {
		weak var weakSelf = self
		dependency.required(ThreadingDependency).backgroundQueue.newExecution {
			execution in
			guard weakSelf != nil else {
				return
			}
			var loadError: ErrorType? = nil
			var models = [Any]()
			do {
				try weakSelf?.loadModels(execution, &models)
			} catch let error {
				loadError = error
			}
			guard weakSelf != nil else {
				return
			}
			execution.continueOnUiQueue {
				guard let strongSelf = weakSelf where models.count > 0 else {
					return
				}
				if let error = loadError {
					strongSelf.dependency.required(CentralUiDependency).pushAlert(.Error, message: String(error))
					return
				}
				strongSelf.models = models
				strongSelf.tableView?.reloadData()
			}
		}

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
		let registration = ensureRegistration(forModelType: model.dynamicType)
		let cell = tableView.dequeueReusableCellWithIdentifier(registration.cellReuseId, forIndexPath: indexPath) as! TableCellUi
		if cell.ui == nil {
			cell.ui = registration.createUi()
			cell.ui.container = cell.contentView
		}
		cell.ui.model = model
		return cell
	}


	public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		let model = models[indexPath.row]
		return ensureRegistration(forModelType: model.dynamicType).heightFor(model, inWidth: tableView.bounds.width)
	}


	// MARK: - Internals


	private var registrations = [ModelUiRegistration]()
	private var models = [Any]()
	private var layoutCache = UiLayoutCache()


}





class TableCellUi: UITableViewCell {

	override func layoutSubviews() {
		super.layoutSubviews()
		ui?.performLayout(inWidth: contentView.bounds.width)
	}

	var ui: Ui!
}





final public class ModelUiRegistration {
	let dependency: DependencyResolver
	var uiFactory: UiDefinition!
	let cellReuseId: String
	let modelType: Any.Type
	let layoutCache: UiLayoutCache?

	public var layoutCacheKeyProvider: ((Any) -> String?)?

	lazy var heightCalculator: Ui = {
		[unowned self] in
		return self.createUi()
	}()


	public init(forModelType modelType: Any.Type, layoutCache: UiLayoutCache?, dependency: DependencyResolver) {
		self.modelType = modelType
		self.layoutCache = layoutCache
		self.dependency = dependency
		cellReuseId = String(reflecting: modelType)
	}


	public func supports(model: Any) -> Bool {
		return model.dynamicType == modelType
	}


	public func createUi() -> Ui {
		let ui = Ui(forModelType: modelType)
		ui.performLayoutInWidth = true
		ui.layoutCache = layoutCache
		ui.layoutCacheKeyProvider = layoutCacheKeyProvider
		dependency.resolve(ui)
		return ui
	}


	public func heightFor(model: Any, inWidth width: CGFloat) -> CGFloat {
		return heightCalculator.heightFor(model, inWidth: width)
	}

}





class TableUiController: UIViewController {
	var ui: TableUi!

	override func viewDidLoad() {
		super.viewDidLoad()
		let tableView = UITableView(frame: view.bounds)
		tableView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
		tableView.separatorStyle = .None
		view.addSubview(tableView)
		ui.tableView = tableView
		adjustTableInsets()
		ui.startLoad()
	}

	private func adjustTableInsets() {
		let isPortrait = view.bounds.width < view.bounds.height
		var top = isPortrait ? CGFloat(20) : CGFloat(0)
		if let navigationBarFrame = self.navigationController?.navigationBar.frame {
			top += navigationBarFrame.size.height
		}
		ui.tableView.contentInset = UIEdgeInsetsMake(top, 0, 0, 0)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		adjustTableInsets()
	}


}





