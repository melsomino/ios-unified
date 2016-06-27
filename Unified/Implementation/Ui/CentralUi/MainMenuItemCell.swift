//
// Created by Michael Vlasov on 30.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

class MainMenuItemCell: UITableViewCell {

	private static let reuseId = "MainMenuItemCell"


	static func registerCellTypes(tableView: UITableView) {
		tableView.registerNib(UINib(nibName: reuseId, bundle: NSBundle(forClass: MainMenuItemCell.self)), forCellReuseIdentifier: reuseId)
	}



	static func cellForItem(item: CentralUiMenuItem, selected: Bool, tableView: UITableView, indexPath: NSIndexPath) -> MainMenuItemCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(reuseId, forIndexPath: indexPath) as! MainMenuItemCell
		cell.setItem(item, selected: selected)
		return cell
	}


	// MARK: - UI Elements


	@IBOutlet weak var itemImage: UIImageView!
	@IBOutlet weak var itemTitle: UILabel!
	@IBOutlet weak var itemCounts: UILabel!
	@IBOutlet weak var selectedItemIndicator: UIView!


	// MARK: - TableViewCell


	override func awakeFromNib() {
		super.awakeFromNib()
		backgroundColor = CentralUiDesign.backgroundColor
		let selectionBackground = UIView()
		selectionBackground.backgroundColor = CentralUiDesign.selectionBackgroundColor
		selectedBackgroundView = selectionBackground
		selectedItemIndicator.backgroundColor = CentralUiDesign.selectedItemIndicatorColor
		var frame = selectedItemIndicator.frame
		switch round(UIScreen.mainScreen().scale) {
			case 1: frame.size.width = 2
			case 2: frame.size.width = 3
			case 3: frame.size.width = 4
			default: frame.size.width = 3
		}
		selectedItemIndicator.frame = frame
	}


	// MARK: - Internals


	private func setItem(item: CentralUiMenuItem, selected: Bool) {
		itemImage.image = item.icon
		itemTitle.text = item.title
		itemCounts.text = ""
		selectedItemIndicator.hidden = !selected

	}
}
