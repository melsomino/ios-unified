//
// Created by Власов М.Ю. on 15.06.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import UIKit




public class TableUi: NSObject, UiDelegate, RepositoryDependent, RepositoryListener, UITableViewDataSource, UITableViewDelegate {

	public weak var controller: UIViewController!
	public final var modelsLoader: ((Execution, inout [Any]) throws -> Void)?
	public final var modelsSync: ((Execution) throws -> Void)?

	public final var tableView: UITableView! {
		didSet {
			if let prev = oldValue {
				prev.dataSource = nil
				prev.delegate = nil
			}
			if let current = tableView {
				current.delegate = self
				current.dataSource = self
				for cellFactory in cellFactories {
					current.registerClass(TableUiCell.self, forCellReuseIdentifier: cellFactory.cellReuseId)
				}
			}
		}
	}


	public func createController(useNavigation useNavigation: Bool = true) -> UIViewController {
		let controller = TableUiController()
		controller.ui = self
		self.controller = controller
		return useNavigation ? UINavigationController(rootViewController: controller) : controller
	}


	public final func ensureCellFactory(forModelType modelType: Any.Type) -> TableUiCellFactory {
		for cellFactory in cellFactories {
			if cellFactory.modelType == modelType {
				return cellFactory
			}
		}

		let cellFactory = TableUiCellFactory(forModelType: modelType, layoutCache: layoutCache, dependency: dependency)
		cellFactories.append(cellFactory)
		tableView?.registerClass(TableUiCell.self, forCellReuseIdentifier: cellFactory.cellReuseId)
		return cellFactory
	}


	public init(dependency: DependencyResolver) {
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
				try weakSelf?.loadModels(execution, models: &models)
			} catch let error {
				loadError = error
			}
			guard weakSelf != nil else {
				return
			}
			execution.continueOnUiQueue {
				guard let strongSelf = weakSelf else {
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


	// MARK: - Overridable


	public func onAction(action: String, args: String?) {

	}

	public func loadModels(execution: Execution, inout models: [Any]) throws {
		try modelsLoader?(execution, &models)
	}

	public func controllerViewDidLoad(controller: UIViewController) {

	}

	// MARK: - Dependency


	public var dependency: DependencyResolver! {
		didSet {
			repository.addListener(self)
		}
	}


	// MARK: - Repository Listener


	public func repositoryChanged(repository: Repository) {
		layoutCache.clear()
		tableView.reloadData()
	}


	// MARK: - Table View DataSource and Delegate


	public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return models.count
	}


	public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let model = models[indexPath.row]
		let cellFactory = ensureCellFactory(forModelType: model.dynamicType)
		let cell = tableView.dequeueReusableCellWithIdentifier(cellFactory.cellReuseId, forIndexPath: indexPath) as! TableUiCell
		if cell.ui == nil {
			let ui = cellFactory.createUi()
			cell.ui = ui
			ui.delegate = self
			ui.container = cell.contentView
			cell.selectionStyle = ui.definition.selectAction != nil ? .Default : .None
		}
		cell.ui.model = model
		return cell
	}


	public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		let model = models[indexPath.row]
		return ensureCellFactory(forModelType: model.dynamicType).heightFor(model, inWidth: tableView.bounds.width)
	}


	public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard let cell = tableView.cellForRowAtIndexPath(indexPath) as? TableUiCell else {
			return
		}

		cell.ui.tryExecuteAction(cell.ui.definition.selectAction)
	}


	// MARK: - Internals


	private var cellFactories = [TableUiCellFactory]()
	private var models = [Any]()
	private var layoutCache = UiLayoutCache()


}





class TableUiCell: UITableViewCell {

	override func layoutSubviews() {
		super.layoutSubviews()
		ui?.performLayout(inWidth: contentView.bounds.width)
	}

	var ui: Ui!
}





public class TableUiCellFactory {
	let dependency: DependencyResolver
	let cellReuseId: String
	let modelType: Any.Type
	let layoutCache: UiLayoutCache?
	var uiDefinition: UiDefinition!


	lazy var heightCalculator: Ui = {
		[unowned self] in
		let ui = self.createUi()
		return ui
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


	public func getLayoutCacheKey(model: Any) -> String? {
		return nil
	}

	public var selectable: Bool {
		return false
	}

	public func select(model: Any) {
	}


	public func createUi() -> Ui {
		let ui = Ui(forModelType: modelType)
		ui.performLayoutInWidth = true
		ui.layoutCache = layoutCache
		ui.layoutCacheKeyProvider = { self.getLayoutCacheKey($0) }
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
		ui.controllerViewDidLoad(self)
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





