//
// Created by Michael Vlasov on 30.05.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

class MainMenuItemCell: UITableViewCell {

	fileprivate static let reuseId = "MainMenuItemCell"


	static func registerCellTypes(_ tableView: UITableView) {
		tableView.register(UINib(nibName: reuseId, bundle: Bundle(for: MainMenuItemCell.self)), forCellReuseIdentifier: reuseId)
	}



	static func cellForItem(_ item: CentralUIMenuItem, selected: Bool, tableView: UITableView, indexPath: IndexPath) -> MainMenuItemCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath) as! MainMenuItemCell
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
		backgroundColor = CentralUIDesign.backgroundColor
		let selectionBackground = UIView()
		selectionBackground.backgroundColor = CentralUIDesign.selectionBackgroundColor
		selectedBackgroundView = selectionBackground
		selectedItemIndicator.backgroundColor = CentralUIDesign.selectedItemIndicatorColor
		var frame = selectedItemIndicator.frame
		switch round(UIScreen.main.scale) {
			case 1: frame.size.width = 2
			case 2: frame.size.width = 3
			case 3: frame.size.width = 4
			default: frame.size.width = 3
		}
		selectedItemIndicator.frame = frame
	}


	// MARK: - Internals


	fileprivate func setItem(_ item: CentralUIMenuItem, selected: Bool) {
		itemImage.image = item.icon
		itemTitle.text = item.title
		itemCounts.text = ""
		selectedItemIndicator.isHidden = !selected

	}
}
