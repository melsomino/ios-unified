//
// Created by Власов М.Ю. on 09.11.16.
// Copyright (c) 2016 Tenzor. All rights reserved.
//

import Foundation

public class EmptyListViewModel {
	public final var message: String
	public init(message: String) {
		self.message = message
	}
}



public class NextListPortionViewModel {
	public static let instance = NextListPortionViewModel()
}



public protocol ListFragmentUpdates: class {
	func insert(item: AnyObject, at index: Int)
	func insert(items: [AnyObject], at index: Int)
	func update(item: AnyObject, at index: Int)
	func delete(at index: Int)
	func delete(count: Int, at index: Int)
}



open class ListFragment: NSObject, FragmentDelegate, ThreadingDependent, RepositoryDependent, RepositoryListener, CentralUIDependent {

	public private(set) var frameDefinition = FrameDefinition.zero

	public final weak var controller: UIViewController!
	public final var emptyMessage = "Нет данных"
	public final var tableView: UITableView! {
		return (controller as? ListFragmentController)?.tableView
	}


	public final var model: AnyObject? {
		didSet {
			onModelChange()
		}
	}
	public final var items = [AnyObject]()


	public final func createController() -> UIViewController {
		let controller = ListFragmentController()
		controller.fragment = self
		self.controller = controller
		return controller
	}



	public final func ensureCellFactory(itemType: AnyObject.Type) -> ListFragmentCellFactory {
		for cellFactory in cellFactories {
			if cellFactory.itemType == itemType {
				return cellFactory
			}
		}

		let cellFactory = ListFragmentCellFactory(itemType: itemType, layoutCache: layoutCache, dependency: dependency)
		cellFactories.append(cellFactory)
		tableView?.register(ListFragmentCell.self, forCellReuseIdentifier: cellFactory.cellReuseId)
		return cellFactory
	}



	private class Updates: ListFragmentUpdates {
		let owner: ListFragment
		init(owner: ListFragment) {
			self.owner = owner
		}



		func insert(item: AnyObject, at index: Int) {
			owner.items.insert(item, at: index)
			owner.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
		}


		private func indexes(start: Int, count: Int) -> [IndexPath] {
			var indexes = [IndexPath]()
			for row in start ..< start + count {
				indexes.append(IndexPath(row: row, section: 0))
			}
			return indexes
		}

		func insert(items: [AnyObject], at index: Int) {
			owner.items.insert(contentsOf: items, at: index)
			owner.tableView.insertRows(at: indexes(start: index, count: items.count), with: .automatic)
		}



		func update(item: AnyObject, at index: Int) {
			owner.items[index] = item
			let cellFactory = owner.ensureCellFactory(itemType: type(of: item))
			if let cacheKey = cellFactory.heightCalculator.getLayoutCacheKey(forModel: item) {
				owner.layoutCache.drop(cacheForKey: cacheKey)
			}
			owner.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
		}



		func delete(at index: Int) {
			owner.items.remove(at: index)
			owner.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
		}

		func delete(count: Int, at index: Int) {
			owner.items.removeSubrange(index ..< index + count)
			owner.tableView.deleteRows(at: indexes(start: index, count: count), with: .fade)
		}

	}



	public final func updateItems(update: (ListFragmentUpdates) -> Void) {
		let updates = Updates(owner: self)
		tableView.beginUpdates()
		update(updates)
		tableView.endUpdates()
	}



	public final func register(itemType: AnyObject.Type, fragment: @escaping () -> Fragment) {
		return ensureCellFactory(itemType: itemType).fragmentFactory = fragment
	}



	public final func startLoad() {
		items = [AnyObject]()
		tableView.reloadData()
		startLoadPortion(restart: true)
	}



	public final func findItem<Model>(test: (Model) -> Bool) -> Model? {
		for item in items {
			if let typed = item as? Model {
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


	open func loadPortion(items: inout [AnyObject], from: Any?, async: Execution) throws -> Any? {
		return nil
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



	open func onInit() {
	}



	open func onResize() {
	}

	open func onModelChange() {
		reloadFrameDefinition()
	}

	open func onItemsLoaded() {
	}


	// MARK: - Fragment delegate


	open func layoutChanged(forFragment fragment: Fragment) {
	}



	// MARK: - Dependency


	open var dependency: DependencyResolver! {
		didSet {
			repository.addListener(self)
		}
	}


	// MARK: - Repository Listener


	open func repositoryChanged(_ repository: Repository) {
		reloadFrameDefinition()
		layoutCache.clear()
		tableView?.reloadData()
	}



	func onLoadingIndicatorRefresh() {
		startLoadPortion(restart: true)
	}


	// MARK: - Table View DataSource and Delegate


	open func onTableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return items.count
	}





	open func onTableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
		let item = items[indexPath.row]
		let cellFactory = ensureCellFactory(itemType: type(of: item))
		let cell = tableView.dequeueReusableCell(withIdentifier: cellFactory.cellReuseId, for: indexPath) as! ListFragmentCell
		if cell.fragment == nil {
			let fragment = cellFactory.createFragment()
			cell.fragment = fragment
			fragment.delegate = self
			fragment.container = cell.contentView
			cell.selectionStyle = fragment.definition.selectAction != nil ? fragment.definition.selectionStyle : .none
		}
		cell.fragment.model = item
		if indexPath.row >= items.count - 10 && nextPortionStart != nil {
			startLoadPortion(restart: false)
		}
		return cell
	}





	open func onTableView(_ tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat {
		let item = items[indexPath.row]
		return ensureCellFactory(itemType: type(of: item)).heightFor(item: item, inWidth: tableView.bounds.width)
	}





	open func onTableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
		guard let cell = tableView.cellForRow(at: indexPath) as? ListFragmentCell else {
			return
		}
		cell.fragment.tryExecuteAction(cell.fragment.definition.selectAction, defaultArgs: nil)
	}


	open func onTableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		guard let cell = cell as? ListFragmentCell, items[indexPath.row] is NextListPortionViewModel else {
			return
		}
		cell.fragment.rootElement.traversal {
			element in
			if let waiting = element as? WaitingElement, let view = waiting.view as? UIActivityIndicatorView {
				view.startAnimating()
			}
		}
	}

	// MARK: - Internals


	private var loading = false
	private var nextPortionStart: Any?

	private var keyboardFrame = CGRect.zero
	private var cellFactories = [ListFragmentCellFactory]()
	private var layoutCache = FragmentLayoutCache()
	fileprivate var loadingIndicator: UIRefreshControl!
	private var reloadingIndicator: UIActivityIndicatorView!
	private var actors = [FrameActor]()


	func keyboardWillAppear(_ notification: Notification) {
		if let frame = ((notification as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
			keyboardFrame = frame
		}
	}



	func keyboardWillDisappear(_ notification: Notification) {
		keyboardFrame = CGRect.zero
	}



	func registerTableView(_ tableView: UITableView) {
		for cellFactory in cellFactories {
			tableView.register(ListFragmentCell.self, forCellReuseIdentifier: cellFactory.cellReuseId)
		}
	}



	private func startLoadPortion(restart: Bool) {
		guard !loading else {
			return
		}
		loading = true
		if restart {
			nextPortionStart = nil
//			reloadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
//			reloadingIndicator.color = UIColor.darkGray
//			let bounds = tableView.bounds
//			let size = reloadingIndicator.bounds.size
//			reloadingIndicator.frame = CGRect(x: bounds.width / 2 - size.width / 2, y: tableView.contentInset.top + size.height / 2, width: size.width, height: size.height)
//			reloadingIndicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
//			tableView.addSubview(reloadingIndicator)
//			reloadingIndicator.startAnimating()
		}
		weak var weakSelf = self
		let _ = threading.backgroundQueue.newExecution {
			async in
			guard weakSelf != nil else {
				return
			}
			var loadError: Error?
			var nextPortionStart = weakSelf?.nextPortionStart
			var portion = [AnyObject]()
			do {
				nextPortionStart = try weakSelf?.loadPortion(items: &portion, from: nextPortionStart, async: async)
			}
			catch let error {
				loadError = error
			}
			guard weakSelf != nil else {
				return
			}
			async.continueOnUiQueue {
				weakSelf?.loadComplete(portion: portion, next: nextPortionStart, resetItems: restart, loadError: loadError)
			}
		}
	}

	private func loadComplete(portion: [AnyObject], next: Any?, resetItems: Bool, loadError: Error?) {
		defer {
			loading = false
		}
		loadingIndicator.endRefreshing()
		reloadingIndicator?.removeFromSuperview()
		reloadingIndicator = nil
		if let error = loadError {
			optionalCentralUI?.push(alert: .error, message: error.userDescription)
			print(error)
			return
		}
		nextPortionStart = next

		if resetItems {
			layoutCache.clear()
			items = portion
			if items.count == 0 {
				items.append(EmptyListViewModel(message: emptyMessage))
			}
			else if nextPortionStart != nil {
				items.append(NextListPortionViewModel.instance)
			}
			tableView?.reloadData()
		}
		else {
			var index = items.count
			updateItems {
				updates in
				if let last = items.last, last is EmptyListViewModel || last is NextListPortionViewModel {
					index -= 1
					updates.delete(at: items.count - 1)
				}
				updates.insert(items: portion, at: index)
				index += portion.count
				if items.count == 0 {
					updates.insert(item: EmptyListViewModel(message: emptyMessage), at: index)
				}
				else if nextPortionStart != nil {
					updates.insert(item: NextListPortionViewModel.instance, at: index)
				}
			}
		}

		onItemsLoaded()
	}




	fileprivate func reloadFrameDefinition() {
		guard let controller = controller, let model = model else {
			return
		}
		var repositoryDefinition: FrameDefinition?
		do {
			repositoryDefinition = try optionalRepository?.findDefinition(for: type(of: model), with: nil, in: FrameDefinition.RepositorySection) as? FrameDefinition
			frameDefinition = repositoryDefinition ?? FrameDefinition.zero
			actors = try frameDefinition.apply(controller: controller, model: model, delegate: self, dependency: dependency)
			tableView.backgroundColor = frameDefinition.backgroundColor
		}
		catch let error {
			optionalCentralUI?.push(alert: .error, message: error.userDescription)
		}
	}
}





class ListFragmentCell: UITableViewCell {

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





open class ListFragmentCellFactory {
	final let dependency: DependencyResolver
	final let cellReuseId: String
	final let itemType: AnyObject.Type
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



	public final func heightFor(item: AnyObject, inWidth width: CGFloat) -> CGFloat {
		return heightCalculator.heightFor(item, inWidth: width)
	}



	public init(itemType: AnyObject.Type, layoutCache: FragmentLayoutCache?, dependency: DependencyResolver) {
		self.itemType = itemType
		self.layoutCache = layoutCache
		self.dependency = dependency
		cellReuseId = String(reflecting: itemType)
	}


	// MARK: - Internals


	private func internalCreateFragment() -> Fragment {
		let fragment = fragmentFactory != nil ? fragmentFactory!() : Fragment(forModelType: itemType)
		fragment.performLayoutInWidth = true
		fragment.layoutCache = layoutCache
		dependency.resolve(fragment)
		if layoutName != nil {
			fragment.layoutName = layoutName!
		}
		return fragment
	}
}




class ListFragmentController: UITableViewController {

	final var fragment: ListFragment!


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
		fragment.reloadFrameDefinition()
		fragment.onInit()
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


	override var preferredStatusBarStyle: UIStatusBarStyle {
		return fragment.frameDefinition.statusBar
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



	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		return fragment.onTableView(tableView, willDisplay: cell, forRowAt: indexPath)
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



