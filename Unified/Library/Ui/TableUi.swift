//
// Created by Власов М.Ю. on 15.06.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import UIKit




public class TableUi: NSObject, RepositoryDependent, RepositoryListener, UITableViewDataSource, UITableViewDelegate {

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
					current.registerClass(TableCellUi.self, forCellReuseIdentifier: cellFactory.cellReuseId)
				}
			}
		}
	}


	public func createController(useNavigation: Bool = true) -> UIViewController {
		let controller = TableUiController()
		controller.ui = self
		self.controller = controller
		return useNavigation ? UINavigationController(rootViewController: controller) : controller
	}


	public final func ensureCellFactory(forModelType modelType: Any.Type) -> TableUiCellFactoryBase {
		for cellFactory in cellFactories {
			if cellFactory.modelType == modelType {
				return cellFactory
			}
		}

		let cellFactory = TableUiCellFactoryBase(forModelType: modelType, layoutCache: layoutCache, dependency: dependency)
		cellFactories.append(cellFactory)
		tableView?.registerClass(TableCellUi.self, forCellReuseIdentifier: cellFactory.cellReuseId)
		return cellFactory
	}


	public final func ensureCellFactory<Model>() -> TableUiCellFactory<Model> {
		let modelType = Model.self
		for cellFactory in cellFactories {
			if cellFactory.modelType == modelType {
				return cellFactory as! TableUiCellFactory<Model>
			}
		}

		let cellFactory = TableUiCellFactory<Model>(layoutCache: layoutCache, dependency: dependency)
		cellFactories.append(cellFactory)
		tableView?.registerClass(TableCellUi.self, forCellReuseIdentifier: cellFactory.cellReuseId)
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
		let cell = tableView.dequeueReusableCellWithIdentifier(cellFactory.cellReuseId, forIndexPath: indexPath) as! TableCellUi
		if cell.ui == nil {
			cell.ui = cellFactory.createUi()
			cell.ui.container = cell.contentView
		}
		cell.ui.model = model
		return cell
	}


	public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		let model = models[indexPath.row]
		return ensureCellFactory(forModelType: model.dynamicType).heightFor(model, inWidth: tableView.bounds.width)
	}


	// MARK: - Internals


	private var cellFactories = [TableUiCellFactoryBase]()
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





public class TableUiCellFactoryBase {
	let dependency: DependencyResolver
	let cellReuseId: String
	let modelType: Any.Type
	let layoutCache: UiLayoutCache?
	var uiDefinition: UiDefinition!


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



public class TableUiCellFactory<Model>: TableUiCellFactoryBase {
	public var onGetLayoutCacheKey: ((Model) -> String?)?
	public var onSelect: ((Model) -> Void)?

	public init(layoutCache: UiLayoutCache?, dependency: DependencyResolver) {
		super.init(forModelType: Model.self, layoutCache: layoutCache, dependency: dependency)
	}


	public override func getLayoutCacheKey(model: Any) -> String? {
		return onGetLayoutCacheKey?(model as! Model)
	}

	public override var selectable: Bool {
		return onSelect != nil
	}


	public override func select(model: Any) {
		onSelect?(model as! Model)
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





