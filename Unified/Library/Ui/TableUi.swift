
//
// Created by Власов М.Ю. on 15.06.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import UIKit




public class TableUi: NSObject, UiDelegate, RepositoryDependent, RepositoryListener, UITableViewDataSource, UITableViewDelegate {

	public final weak var controller: UIViewController!
	public final var modelsLoader: ((Execution, inout [Any]) throws -> Void)?
	public final var modelsSync: ((Execution) throws -> Void)?
	public final var tableView: UITableView! {
		didSet {
			internalDidSetTableView(oldValue)
		}
	}

	public final func createController(useNavigation useNavigation: Bool = true) -> UIViewController {
		return internalCreateController(useNavigation: useNavigation)
	}

	public final func ensureCellFactory(forModelType modelType: Any.Type) -> TableUiCellFactory {
		return internalEnsureCellFactory(forModelType: modelType)
	}

	public final func startLoad() {
		internalStartLoad()
	}

	public init(dependency: DependencyResolver) {
		super.init()
		dependency.resolve(self)
	}


	// MARK: - Overridable


	public func onAction(action: String, args: String?) {
	}

	public func loadModels(execution: Execution, inout models: [Any]) throws {
		try defaultLoadModels(execution, models: &models)
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

	private func internalDidSetTableView(oldValue: UITableView!) {
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

	private func internalCreateController(useNavigation useNavigation: Bool = true) -> UIViewController {
		let controller = TableUiController()
		controller.ui = self
		self.controller = controller
		return useNavigation ? UINavigationController(rootViewController: controller) : controller
	}

	private func internalEnsureCellFactory(forModelType modelType: Any.Type) -> TableUiCellFactory {
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


	private func internalStartLoad() {
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

	private func defaultLoadModels(execution: Execution, inout models: [Any]) throws {
		try modelsLoader?(execution, &models)
	}

}





class TableUiCell: UITableViewCell {

	final var ui: Ui!

	// MARK: - UITableViewCell

	override func layoutSubviews() {
		super.layoutSubviews()
		ui?.performLayout(inWidth: contentView.bounds.width)
	}

}





public class TableUiCellFactory {
	final let dependency: DependencyResolver
	final let cellReuseId: String
	final let modelType: Any.Type
	final let layoutCache: UiLayoutCache?
	final var uiDefinition: UiDefinition!
	public final var layoutName: String?

	final lazy var heightCalculator: Ui = {
		[unowned self] in
		return self.createUi()
	}()

	public final func createUi() -> Ui {
		return internalCreateUi()
	}

	public final func heightFor(model: Any, inWidth width: CGFloat) -> CGFloat {
		return heightCalculator.heightFor(model, inWidth: width)
	}

	public init(forModelType modelType: Any.Type, layoutCache: UiLayoutCache?, dependency: DependencyResolver) {
		self.modelType = modelType
		self.layoutCache = layoutCache
		self.dependency = dependency
		cellReuseId = String(reflecting: modelType)
	}


	// MARK: - Internals


	private func internalCreateUi() -> Ui {
		let ui = Ui(forModelType: modelType)
		ui.performLayoutInWidth = true
		ui.layoutCache = layoutCache
		dependency.resolve(ui)
		if layoutName != nil {
			ui.layoutName = layoutName!
		}
		return ui
	}
}




class TableUiController: UIViewController {

	final var ui: TableUi!


	// MARK: - UIViewController


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

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		adjustTableInsets()
	}


	// MARK: - Internals


	private func adjustTableInsets() {
		let isPortrait = view.bounds.width < view.bounds.height
		var top = isPortrait ? CGFloat(20) : CGFloat(0)
		if let navigationBarFrame = self.navigationController?.navigationBar.frame {
			top += navigationBarFrame.size.height
		}
		ui.tableView.contentInset = UIEdgeInsetsMake(top, 0, 0, 0)
	}

}



