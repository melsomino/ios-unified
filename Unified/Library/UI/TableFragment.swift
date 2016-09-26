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


public class EmptyTableFragment {
	public var message: String
	public init(message: String) {
		self.message = message
	}
}

public protocol TableModelUpdates {
	func insert(model: Any, at index: Int)



	func update(model: Any, at index: Int)



	func delete(index: Int)
}

public class TableFragment: NSObject, FragmentDelegate, ThreadingDependent, RepositoryDependent, RepositoryListener, CentralUIDependent {

	public final weak var controller: UIViewController!
	public final var modelsLoader: ((Execution, inout [Any]) throws -> Void)?
	public final var modelsSync: ((Execution) throws -> Void)?
	public final var emptyMessage = "Нет данных"
	public final var tableView: UITableView! {
		return (controller as? TableFragmentController)?.tableView
	}


	public final var models = [Any]()


	public final func createController() -> UIViewController {
		return internalCreateController()
	}



	public final func setBottomBar(model model: Any?) {
		internalSetBottomBar(model: model)
	}



	public final func reflectBottomBarModelChanges() {
		guard let model = bottomBarFragment?.model else {
			return
		}
		UIView.animateWithDuration(0.25, animations: {
			self.bottomBarFragment!.model = model
			self.adjustBottomBar()
		})
	}



	public final func ensureCellFactory(forModelType modelType: Any.Type) -> CellFragmentFactory {
		return internalEnsureCellFactory(forModelType: modelType)
	}

	private class ModelUpdates: TableModelUpdates {
		let owner: TableFragment
		init(owner: TableFragment) {
			self.owner = owner
		}



		func insert(model: Any, at index: Int) {
			owner.models.insert(model, atIndex: index)
			owner.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Fade)
		}



		func update(model: Any, at index: Int) {
			owner.models[index] = model
			owner.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Fade)
		}



		func delete(index: Int) {
			owner.models.removeAtIndex(index)
			owner.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Fade)
		}

	}

	public final func updateModels(@noescape update: (TableModelUpdates) -> Void) {
		let updates = ModelUpdates(owner: self)
		tableView.beginUpdates()
		update(updates)
		tableView.endUpdates()
	}



	public final func registerFragmentClass(for modelType: Any.Type, fragmentClass: () -> Fragment) {
		return ensureCellFactory(forModelType: modelType).fragmentFactory = fragmentClass
	}



	public final func startLoad() {
		models = [Any]()
		tableView.reloadData()
		internalStartLoad(showLoadingIndicator: true)
	}



	public final func findModel<Model>(test: (Model) -> Bool) -> Model? {
		for model in models {
			if let typed = model as? Model {
				if test(typed) {
					return typed
				}
			}
		}
		return nil
	}



	public init(dependency: DependencyResolver) {
		super.init()
		dependency.resolve(self)
	}


	// MARK: - Overridable


	public func loadModels(execution: Execution, inout models: [Any]) throws {
		try defaultLoadModels(execution, models: &models)
	}



	public func onAction(action: String, args: String?) {
	}



	public func onControllerAttached() {
	}



	public func onResize() {
		adjustBottomBar()
	}



	public func onModelsLoaded() {
	}


	// MARK: - Fragment delegate


	public func layoutChanged(forFragment fragment: Fragment) {
		if fragment == bottomBarFragment {
			UIView.animateWithDuration(0.25, animations: {
				self.adjustBottomBar()
			})
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
			let fragment = cellFactory.createFragment()
			cell.fragment = fragment
			fragment.delegate = self
			fragment.container = cell.contentView
			cell.selectionStyle = fragment.definition.selectAction != nil ? fragment.definition.selectionStyle : .None
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
		cell.fragment.tryExecuteAction(cell.fragment.definition.selectAction, defaultArgs: nil)
	}




	// MARK: - Internals


	private var cellFactories = [CellFragmentFactory]()
	private var layoutCache = FragmentLayoutCache()
	private var loadingIndicator: UIRefreshControl!
	private var reloadingIndicator: UIActivityIndicatorView!

	private var bottomBarFragment: Fragment?

	public final func internalSetBottomBar(model model: Any?) {
		guard let model = model else {
			if let fragment = bottomBarFragment {
				fragment.container?.removeFromSuperview()
				bottomBarFragment = nil
			}
			return
		}
		if bottomBarFragment == nil {
			bottomBarFragment = Fragment(forModelType: model.dynamicType)
			bottomBarFragment!.dependency = dependency
			bottomBarFragment!.delegate = self
			let container = UIView(frame: CGRectZero)
			bottomBarFragment!.container = container
			controller.view.addSubview(container)
		}
		bottomBarFragment!.model = model
		adjustBottomBar()
	}




	private func adjustBottomBar() {
		guard let controller = controller as? UITableViewController else {
			return
		}
		var insets = tableView.contentInset
		guard let fragment = bottomBarFragment, container = fragment.container else {
			insets.bottom = 0
			tableView.contentInset = insets
			return
		}
		let bounds = controller.view.bounds
		let contentOffset = controller.tableView.contentOffset
		fragment.performLayout(inWidth: bounds.width)
		var frame = fragment.frame
		frame.origin.y = contentOffset.y + bounds.size.height - frame.size.height
		container.frame = frame
		controller.view.bringSubviewToFront(container)
		insets.bottom = frame.height
		tableView.contentInset = insets
	}



	func registerTableView(tableView: UITableView) {
		for cellFactory in cellFactories {
			tableView.registerClass(TableFragmentCell.self, forCellReuseIdentifier: cellFactory.cellReuseId)
		}
	}





	private func internalCreateController() -> UIViewController {
		let controller = TableFragmentController()
		controller.fragment = self
		self.controller = controller
		return controller
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
			reloadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
			reloadingIndicator.color = UIColor.darkGrayColor()
			let bounds = tableView.bounds
			let size = reloadingIndicator.bounds.size
			reloadingIndicator.frame = CGRectMake(bounds.width / 2 - size.width / 2, tableView.contentInset.top + size.height / 2, size.width, size.height)
			reloadingIndicator.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
			tableView.addSubview(reloadingIndicator)
			reloadingIndicator.startAnimating()
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
				if showLoadingIndicator {
					strongSelf.reloadingIndicator?.removeFromSuperview()
					strongSelf.reloadingIndicator = nil
				}
				else {
					strongSelf.loadingIndicator.endRefreshing()
				}
				if let error = loadError {
					strongSelf.optionalCentralUI?.pushAlert(.error, message: strongSelf.errorUserMessage(error))
					print(error)
					return
				}
				if models.count == 0 {
					models.append(EmptyTableFragment(message: strongSelf.emptyMessage))
				}
				strongSelf.layoutCache.clear()
				strongSelf.models = models
				strongSelf.tableView?.reloadData()
				strongSelf.onModelsLoaded()
			}
		}
	}



	private func defaultLoadModels(execution: Execution, inout models: [Any]) throws {
		try modelsLoader?(execution, &models)
	}



	private func errorUserMessage(error: ErrorType) -> String {
		switch error {
			case let error as NSError:
				return error.localizedDescription
			default:
				return String(error)
		}
	}

}





class TableFragmentCell: UITableViewCell {

	final var fragment: Fragment!


	// MARK: - UITableViewCell


	override func layoutSubviews() {
		super.layoutSubviews()
		fragment?.performLayout(inWidth: contentView.bounds.width)
	}



	override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		change(highlight: currentHighlight, select: selected)
	}



	override func setHighlighted(highlighted: Bool, animated: Bool) {
		super.setHighlighted(highlighted, animated: animated)
		change(highlight: highlighted, select: currentSelect)
	}


	// MARK: - Internals

	private var currentHighlight = false
	private var currentSelect = false


	private func change(highlight highlight: Bool, select: Bool) {
		let prevHighlight = currentHighlight || currentSelect
		currentHighlight = highlight
		currentSelect = select
		let newHighlight = highlight || select
		guard prevHighlight != newHighlight else {
			return
		}
		if let fragment = fragment {
			if selectionStyle != .None {
				fragment.reflectCellHighlight(newHighlight)
			}
		}
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
		return self.createFragment()
	}()

	public final func createFragment() -> Fragment {
		return internalCreateFragment()
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


	private func internalCreateFragment() -> Fragment {
		let fragment = fragmentFactory != nil ? fragmentFactory!() : Fragment(forModelType: modelType)
		fragment.performLayoutInWidth = true
		fragment.layoutCache = layoutCache
		dependency.resolve(fragment)
		if layoutName != nil {
			fragment.layoutName = layoutName!
		}
		return fragment
	}
}




class TableFragmentController: UITableViewController {

	final var fragment: TableFragment!


	// MARK: - UIViewController


	override func viewDidLoad() {
		super.viewDidLoad()
		navigationController?.navigationBar.translucent = false
//		automaticallyAdjustsScrollViewInsets = false

		fragment.registerTableView(tableView)
		tableView.separatorStyle = .None
		adjustTableInsets()
		fragment.loadingIndicator = UIRefreshControl()
		refreshControl = fragment.loadingIndicator
		fragment.loadingIndicator.addTarget(self, action: #selector(onLoadingIndicatorRefresh), forControlEvents: .ValueChanged)
		fragment.onControllerAttached()
		fragment.startLoad()
	}



	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		adjustTableInsets()
		fragment.onResize()
	}


	// MARK: - UITableViewController


	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return .LightContent
	}



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
//		let isPortrait = view.bounds.width < view.bounds.height
//		var top = isPortrait ? CGFloat(20) : CGFloat(0)
//		if let navigationBarFrame = self.navigationController?.navigationBar.frame {
//			top += navigationBarFrame.size.height
//		}
//		if let superview = tableView?.superview {
//			tableView.frame = UIEdgeInsetsInsetRect(superview.bounds, UIEdgeInsetsMake(top, 0, 0, 0))
//		}
//		fragment.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
	}

}



