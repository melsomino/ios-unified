//
// Created by Michael Vlasov on 03.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public struct TableCellContext {
	public let tableView: UITableView
	public let indexPath: NSIndexPath
	public let layoutCache: UiLayoutCache
	public let dependency: DependencyResolver

	public var width: CGFloat {
		return tableView.bounds.width
	}

	public func cellWithReuseId<Cell: UITableViewCell>(reuseId: String, initCell: (Cell) -> Void) -> Cell {
		let cell = tableView.dequeueReusableCellWithIdentifier(reuseId, forIndexPath: indexPath) as! Cell
		initCell(cell)
		return cell
	}

	public func cachedHeightForKey(key: String) -> CGFloat? {
		return layoutCache.cachedHeightForWidth(tableView.bounds.width, key: key)
	}
}
