//
// Created by Michael Vlasov on 03.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

private struct Insertion<Item> {
	let item: Item
	var index: Int
}

public struct SortedTableSync<Item> {


	private let deletions: [Int]
	private let insertions: [Insertion<Item>]

	public static func prepare<Key>(oldItems oldItems: [Item], inserted: [Item], deletedKeys: Set<Key>,
		keyOfItem: (Item) -> Key, isOrderedBefore: (Item, Item) -> Bool) -> SortedTableSync<Item> {

		var newItems = oldItems
		var oldIndexByKey = [Key: Int]()
		var index = 0
		for item in oldItems {
			oldIndexByKey[keyOfItem(item)] = index
			index += 1
		}

		var deletions = [Int]()
		for key in deletedKeys {
			if let oldIndex = oldIndexByKey[key] {
				deletions.append(oldIndex)
				newItems.removeAtIndex(oldIndex)
			}
		}

		deletions.sortInPlace({ a, b in b < a })

		var insertions = [Insertion<Item>]()
		for item in inserted {
			let insertionIndex = newItems.insertionIndexOf(item, isOrderedBefore: isOrderedBefore)
			insertions.append(Insertion(item: item, index: insertionIndex))
			newItems.insert(item, atIndex: insertionIndex)
		}

		return SortedTableSync<Item>(deletions: deletions, insertions: insertions)
	}



	func update(tableView: UITableView, @noescape deleteItem: (Int) -> Void, @noescape insertItem: (Item, Int) -> Void) {
		tableView.beginUpdates()
		if deletions.count > 0 {
			var deletedIndexPaths = [NSIndexPath]()
			for index in deletions {
				deleteItem(index)
				deletedIndexPaths.append(NSIndexPath(forRow: index, inSection: 0))
			}
			tableView.deleteRowsAtIndexPaths(deletedIndexPaths, withRowAnimation: .Automatic)
		}
		if insertions.count > 0 {
			var indexes = [Int]()
			for insertion in insertions {
				insertItem(insertion.item, insertion.index)
				for i in 0 ..< indexes.count {
					if indexes[i] >= insertion.index {
						indexes[i] += 1
					}
				}
				indexes.append(insertion.index)
			}
			var insertedIndexPaths = [NSIndexPath]()
			for index in indexes {
				insertedIndexPaths.append(NSIndexPath(forRow: index, inSection: 0))
			}
			tableView.insertRowsAtIndexPaths(insertedIndexPaths, withRowAnimation: .Automatic)
		}
		tableView.endUpdates()
	}
}


