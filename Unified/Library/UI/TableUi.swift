//
// Created by Власов М.Ю. on 15.06.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import UIKit


public enum TableFragmentModelsState {
	case predefined
	case loading
	case loaded
	case failed(ErrorType)
}



public class TableFragment: NSObject, FragmentDelegate, ThreadingDependent, RepositoryDependent, RepositoryListener {

	public final weak var controller: UIViewController!
	public final var modelsLoader: ((Execution, inout [Any]) throws -> Void)?
	public final var modelsSync: ((Execution) throws -> Void)?
	public final var tableView: UITableView! { return (controller as? TableFragmentController)?.tableView }


	public final func createController(useNavigation useNavigation: Bool = true) -> UIViewController {
		return internalCreateController(useNavigation: useNavigation)
	}


	public final func ensureCellFactory(forModelType modelType: Any.Type) -> CellFragmentFactory {
		return internalEnsureCellFactory(forModelType: modelType)
	}


	public final func registerFragmentClass(for modelType: Any.Type, fragmentClass: () -> Fragment) {
		return ensureCellFactory(forModelType: modelType).fragmentFactory = fragmentClass
	}


	public final func startLoad() {
		models = [Any]()
		tableView.reloadData()
		internalStartLoad(showLoadingIndicator: true)
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

	public func onAttachToController(controller: UIViewController) {
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
		tableView?.reloadData()
	}



	func onLoadingIndicatorRefresh() {
		internalStartLoad(showLoadingIndicator: false)
	}


	// MARK: - Table View DataSource and Delegate


	public func onTableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return models.count
	}





	public func onTableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let model = models[indexPath.row]
		let cellFactory = ensureCellFactory(forModelType: model.dynamicType)
		let cell = tableView.dequeueReusableCellWithIdentifier(cellFactory.cellReuseId, forIndexPath: indexPath) as! TableFragmentCell
		if cell.fragment == nil {
			let ui = cellFactory.createUi()
			cell.fragment = ui
			ui.delegate = self
			ui.container = cell.contentView
			cell.selectionStyle = ui.definition.selectAction != nil ? .Default : .None
		}
		cell.fragment.model = model
		return cell
	}





	public func onTableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		let model = models[indexPath.row]
		return ensureCellFactory(forModelType: model.dynamicType).heightFor(model, inWidth: tableView.bounds.width)
	}





	public func onTableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard let cell = tableView.cellForRowAtIndexPath(indexPath) as? TableFragmentCell else {
			return
		}
		cell.fragment.tryExecuteAction(cell.fragment.definition.selectAction)
	}


	// MARK: - Internals


	private var cellFactories = [CellFragmentFactory]()
	private var models = [Any]()
	private var layoutCache = FragmentLayoutCache()
	private var loadingIndicator: UIRefreshControl!





	func registerTableView(tableView: UITableView) {
		for cellFactory in cellFactories {
			tableView.registerClass(TableFragmentCell.self, forCellReuseIdentifier: cellFactory.cellReuseId)
		}
	}





	private func internalCreateController(useNavigation useNavigation: Bool = true) -> UIViewController {
		let controller = TableFragmentController()
		controller.fragment = self
		self.controller = controller
		return useNavigation ? UINavigationController(rootViewController: controller) : controller
	}





	private func internalEnsureCellFactory(forModelType modelType: Any.Type) -> CellFragmentFactory {
		for cellFactory in cellFactories {
			if cellFactory.modelType == modelType {
				return cellFactory
			}
		}

		let cellFactory = CellFragmentFactory(forModelType: modelType, layoutCache: layoutCache, dependency: dependency)
		cellFactories.append(cellFactory)
		tableView?.registerClass(TableFragmentCell.self, forCellReuseIdentifier: cellFactory.cellReuseId)
		return cellFactory
	}





	private func internalStartLoad(showLoadingIndicator showLoadingIndicator: Bool) {
		if showLoadingIndicator {
			tableView.setContentOffset(CGPointMake(0, tableView.contentOffset.y - loadingIndicator.frame.size.height), animated: true)
			loadingIndicator.beginRefreshing()
		}
		weak var weakSelf = self
		threading.backgroundQueue.newExecution {
			execution in
			guard weakSelf != nil else {
				return
			}
			var loadError: ErrorType? = nil
			var models = [Any]()
			do {
				try weakSelf?.loadModels(execution, models: &models)
			}
				catch let error {
				loadError = error
			}
			guard weakSelf != nil else {
				return
			}
			execution.continueOnUiQueue {
				guard let strongSelf = weakSelf else {
					return
				}
				strongSelf.loadingIndicator.endRefreshing()
				if let error = loadError {
					strongSelf.dependency.required(CentralUiDependency).pushAlert(.Error, message: String(error))
					print(error)
					return
				}
				strongSelf.models = models
				strongSelf.tableView?.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
			}
		}
	}

	private func defaultLoadModels(execution: Execution, inout models: [Any]) throws {
		try modelsLoader?(execution, &models)
	}

}





class TableFragmentCell: UITableViewCell {

	final var fragment: Fragment!

	// MARK: - UITableViewCell

	override func layoutSubviews() {
		super.layoutSubviews()
		fragment?.performLayout(inWidth: contentView.bounds.width)
	}

}





public class CellFragmentFactory {
	final let dependency: DependencyResolver
	final let cellReuseId: String
	final let modelType: Any.Type
	final let layoutCache: FragmentLayoutCache?
	final var fragmentDefinition: FragmentDefinition!
	public final var fragmentFactory: (() -> Fragment)?
	public final var layoutName: String?

	final lazy var heightCalculator: Fragment = {
		[unowned self] in
		return self.createUi()
	}()

	public final func createUi() -> Fragment {
		return internalCreateUi()
	}

	public final func heightFor(model: Any, inWidth width: CGFloat) -> CGFloat {
		return heightCalculator.heightFor(model, inWidth: width)
	}

	public init(forModelType modelType: Any.Type, layoutCache: FragmentLayoutCache?, dependency: DependencyResolver) {
		self.modelType = modelType
		self.layoutCache = layoutCache
		self.dependency = dependency
		cellReuseId = String(reflecting: modelType)
	}


	// MARK: - Internals


	private func internalCreateUi() -> Fragment {
		let ui = fragmentFactory != nil ? fragmentFactory!() : Fragment(forModelType: modelType)
		ui.performLayoutInWidth = true
		ui.layoutCache = layoutCache
		dependency.resolve(ui)
		if layoutName != nil {
			ui.layoutName = layoutName!
		}
		return ui
	}
}




class TableFragmentController: UITableViewController {

	final var fragment: TableFragment!


	// MARK: - UIViewController


	override func viewDidLoad() {
		super.viewDidLoad()
		fragment.registerTableView(tableView)
		tableView.separatorStyle = .None
//		adjustTableInsets()
		fragment.loadingIndicator = UIRefreshControl()
		refreshControl = fragment.loadingIndicator
		fragment.loadingIndicator.addTarget(self, action: #selector(onLoadingIndicatorRefresh), forControlEvents: .ValueChanged)
		fragment.onAttachToController(self)
		fragment.startLoad()
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
//		adjustTableInsets()
	}


	// MARK: - UITableViewController


	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return fragment.onTableView(tableView, numberOfRowsInSection: section)
	}


	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return fragment.onTableView(tableView, cellForRowAtIndexPath: indexPath)
	}


	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return fragment.onTableView(tableView, heightForRowAtIndexPath: indexPath)
	}


	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		return fragment.onTableView(tableView, didSelectRowAtIndexPath: indexPath)
	}


	// MARK: - Internals

	@objc private func onLoadingIndicatorRefresh() {
		fragment.onLoadingIndicatorRefresh()
	}

	private func adjustTableInsets() {
		let isPortrait = view.bounds.width < view.bounds.height
		var top = isPortrait ? CGFloat(20) : CGFloat(0)
		if let navigationBarFrame = self.navigationController?.navigationBar.frame {
			top += navigationBarFrame.size.height
		}
		fragment.tableView.contentInset = UIEdgeInsetsMake(top, 0, 0, 0)
	}

}



