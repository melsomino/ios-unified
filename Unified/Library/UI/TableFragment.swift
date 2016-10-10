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
	case failed(Error)
}


open class EmptyTableFragment {
	open var message: String
	public init(message: String) {
		self.message = message
	}
}

public protocol TableModelUpdates {
	func insert(_ model: Any, at index: Int)



	func update(_ model: Any, at index: Int)



	func delete(_ index: Int)
}

open class TableFragment: NSObject, FragmentDelegate, ThreadingDependent, RepositoryDependent, RepositoryListener, CentralUIDependent {

	public final weak var controller: UIViewController!
	public final var modelsLoader: ((Execution, inout [Any]) throws -> Void)?
	public final var modelsSync: ((Execution) throws -> Void)?
	public final var emptyMessage = "Нет данных"
	public final var tableView: UITableView! {
		return (controller as? TableFragmentController)?.tableView
	}


	open private(set) var bottomBarFragment: Fragment?

	public final var models = [Any]()


	public final func createController() -> UIViewController {
		return internalCreateController()
	}



	public final func setBottomBar(model: Any?, fragment: () -> Fragment) {
		internalSetBottomBar(model: model, fragment: fragment)
	}



	public final func reflectBottomBarModelChanges() {
		guard let model = bottomBarFragment?.model else {
			return
		}
		UIView.animate(withDuration: 0.25, animations: {
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



		func insert(_ model: Any, at index: Int) {
			owner.models.insert(model, at: index)
			owner.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .fade)
		}



		func update(_ model: Any, at index: Int) {
			owner.models[index] = model
			let cellFactory = owner.ensureCellFactory(forModelType: type(of: model))
			if let cacheKey = cellFactory.heightCalculator.getLayoutCacheKey(forModel: model) {
				owner.layoutCache.drop(cacheForKey: cacheKey)
			}
			owner.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
		}



		func delete(_ index: Int) {
			owner.models.remove(at: index)
			owner.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
		}

	}

	public final func updateModels(_ update: (TableModelUpdates) -> Void) {
		let updates = ModelUpdates(owner: self)
		tableView.beginUpdates()
		update(updates)
		tableView.endUpdates()
	}



	public final func registerFragmentClass(for modelType: Any.Type, fragmentClass: @escaping () -> Fragment) {
		return ensureCellFactory(forModelType: modelType).fragmentFactory = fragmentClass
	}



	public final func startLoad() {
		models = [Any]()
		tableView.reloadData()
		internalStartLoad(showLoadingIndicator: true)
	}



	public final func findModel<Model>(_ test: (Model) -> Bool) -> Model? {
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


	open func loadModels(_ execution: Execution, models: inout [Any]) throws {
		try defaultLoadModels(execution, models: &models)
	}



	open func onAction(_ action: String, args: String?) {
	}



	open func onAppear() {
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
	}



	open func onDisappear() {
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
	}



	open func onControllerAttached() {
	}



	open func onResize() {
		adjustBottomBar()
	}



	open func onModelsLoaded() {
	}


	// MARK: - Fragment delegate


	open func layoutChanged(forFragment fragment: Fragment) {
		if fragment == bottomBarFragment {
			UIView.animate(withDuration: 0.25, animations: {
				self.adjustBottomBar()
			})
		}
	}



	// MARK: - Dependency


	open var dependency: DependencyResolver! {
		didSet {
			repository.addListener(self)
		}
	}


	// MARK: - Repository Listener


	open func repositoryChanged(_ repository: Repository) {
		layoutCache.clear()
		tableView?.reloadData()
	}



	func onLoadingIndicatorRefresh() {
		internalStartLoad(showLoadingIndicator: false)
	}


	// MARK: - Table View DataSource and Delegate


	open func onTableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return models.count
	}





	open func onTableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
		let model = models[indexPath.row]
		let cellFactory = ensureCellFactory(forModelType: type(of: model))
		let cell = tableView.dequeueReusableCell(withIdentifier: cellFactory.cellReuseId, for: indexPath) as! TableFragmentCell
		if cell.fragment == nil {
			let fragment = cellFactory.createFragment()
			cell.fragment = fragment
			fragment.delegate = self
			fragment.container = cell.contentView
			cell.selectionStyle = fragment.definition.selectAction != nil ? fragment.definition.selectionStyle : .none
		}
		cell.fragment.model = model
		return cell
	}





	open func onTableView(_ tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat {
		let model = models[indexPath.row]
		return ensureCellFactory(forModelType: type(of: model)).heightFor(model, inWidth: tableView.bounds.width)
	}





	open func onTableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
		guard let cell = tableView.cellForRow(at: indexPath) as? TableFragmentCell else {
			return
		}
		cell.fragment.tryExecuteAction(cell.fragment.definition.selectAction, defaultArgs: nil)
	}




	// MARK: - Internals


	private var keyboardFrame = CGRect.zero
	private var cellFactories = [CellFragmentFactory]()
	private var layoutCache = FragmentLayoutCache()
	fileprivate var loadingIndicator: UIRefreshControl!
	private var reloadingIndicator: UIActivityIndicatorView!


	func keyboardWillAppear(_ notification: Notification) {
		if let frame = ((notification as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
			keyboardFrame = frame
			adjustBottomBar()
		}
	}



	func keyboardWillDisappear(_ notification: Notification) {
		keyboardFrame = CGRect.zero
		adjustBottomBar()
	}



	public final func internalSetBottomBar(model: Any?, fragment: () -> Fragment) {
		guard let model = model else {
			if let fragment = bottomBarFragment {
				fragment.container?.removeFromSuperview()
				bottomBarFragment = nil
			}
			return
		}
		if bottomBarFragment == nil {
			bottomBarFragment = fragment()
			bottomBarFragment!.dependency = dependency
			bottomBarFragment!.delegate = self
			let container = UIView(frame: CGRect.zero)
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
		guard let fragment = bottomBarFragment, let container = fragment.container else {
			insets.bottom = 0
			tableView.contentInset = insets
			return
		}
		var bounds = controller.view.bounds
		if keyboardFrame.height > 0 {
			bounds.size.height -= keyboardFrame.height
		}
		let contentOffset = controller.tableView.contentOffset
		fragment.performLayout(inWidth: bounds.width)
		var frame = fragment.frame
		frame.origin.y = contentOffset.y + bounds.size.height - frame.size.height
		container.frame = frame
		controller.view.bringSubview(toFront: container)
		insets.bottom = frame.height
		tableView.contentInset = insets
	}



	func registerTableView(_ tableView: UITableView) {
		for cellFactory in cellFactories {
			tableView.register(TableFragmentCell.self, forCellReuseIdentifier: cellFactory.cellReuseId)
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
		tableView?.register(TableFragmentCell.self, forCellReuseIdentifier: cellFactory.cellReuseId)
		return cellFactory
	}





	private func internalStartLoad(showLoadingIndicator: Bool) {
		if showLoadingIndicator {
			reloadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
			reloadingIndicator.color = UIColor.darkGray
			let bounds = tableView.bounds
			let size = reloadingIndicator.bounds.size
			reloadingIndicator.frame = CGRect(x: bounds.width / 2 - size.width / 2, y: tableView.contentInset.top + size.height / 2, width: size.width, height: size.height)
			reloadingIndicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
			tableView.addSubview(reloadingIndicator)
			reloadingIndicator.startAnimating()
		}
		weak var weakSelf = self
		threading.backgroundQueue.newExecution {
			execution in
			guard weakSelf != nil else {
				return
			}
			var loadError: Error? = nil
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



	private func defaultLoadModels(_ execution: Execution, models: inout [Any]) throws {
		try modelsLoader?(execution, &models)
	}



	private func errorUserMessage(_ error: Error) -> String {
		switch error {
			case let error as NSError:
				return error.localizedDescription
			default:
				return String(describing: error)
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



	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		change(highlight: currentHighlight, select: selected)
	}



	override func setHighlighted(_ highlighted: Bool, animated: Bool) {
		super.setHighlighted(highlighted, animated: animated)
		change(highlight: highlighted, select: currentSelect)
	}


	// MARK: - Internals

	private var currentHighlight = false
	private var currentSelect = false


	private func change(highlight: Bool, select: Bool) {
		let prevHighlight = currentHighlight || currentSelect
		currentHighlight = highlight
		currentSelect = select
		let newHighlight = highlight || select
		guard prevHighlight != newHighlight else {
			return
		}
		if let fragment = fragment {
			if selectionStyle != .none {
				fragment.reflectCellHighlight(newHighlight)
			}
		}
	}

}





open class CellFragmentFactory {
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



	public final func heightFor(_ model: Any, inWidth width: CGFloat) -> CGFloat {
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
		navigationController?.navigationBar.isTranslucent = false
//		automaticallyAdjustsScrollViewInsets = false

		fragment.registerTableView(tableView)
		tableView.separatorStyle = .none
		adjustTableInsets()
		fragment.loadingIndicator = UIRefreshControl()
		refreshControl = fragment.loadingIndicator
		fragment.loadingIndicator.addTarget(self, action: #selector(onLoadingIndicatorRefresh), for: .valueChanged)
		fragment.onControllerAttached()
		fragment.startLoad()
	}



	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		adjustTableInsets()
		fragment.onResize()
	}



	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		fragment.onAppear()
	}



	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		fragment.onDisappear()
	}


	// MARK: - UITableViewController


	override var preferredStatusBarStyle : UIStatusBarStyle {
		return .lightContent
	}



	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return fragment.onTableView(tableView, numberOfRowsInSection: section)
	}



	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return fragment.onTableView(tableView, cellForRowAtIndexPath: indexPath)
	}



	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return fragment.onTableView(tableView, heightForRowAtIndexPath: indexPath)
	}



	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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



