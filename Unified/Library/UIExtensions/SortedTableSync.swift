//
// Created by Michael Vlasov on 03.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

enum CollectionUpdateType {
	case insert, delete, move, reload
}

class CollectionSectionUpdate<Section> {
	let section: Section
	let type: CollectionUpdateType
	let index: Int
	let indexNew: Int

	init(section: Section, type: CollectionUpdateType, index: Int, indexNew: Int) {
		self.section = section
		self.type = type
		self.index = index
		self.indexNew = indexNew
	}
}

class CollectionItemUpdate<Item> {
	let item: Item
	let type: CollectionUpdateType
	let index: NSIndexPath
	let indexNew: NSIndexPath

	init(item: Item, type: CollectionUpdateType, index: NSIndexPath, indexNew: NSIndexPath) {
		self.item = item
		self.type = type
		self.index = index
		self.indexNew = indexNew
	}
}



public struct CollectionSync<Section, Item> {

	let sameSections: (Section, Section) -> Bool
	let sameItems: (Item, Item) -> Bool

	func calculateUpdates(forOldModel oldSections: [Section]?, newModel newSections: [Section]?,
		sectionsPriorityOrder: [String],
		eliminatesDuplicates: Bool,
		completion: ([Section]?, [CollectionSectionUpdate<Section>]?, [CollectionItemUpdate<Item>]?) -> Void) {

		// Find inserted sections
		for newIndex in 0 ..< (newSections?.count ?? 0) {
			let newSection = newSections![newIndex]
			var oldIndex: Int?
			if oldSections != nil {
				oldIndex = oldSections!.indexOf({ sameSections($0, newSection) })
			}

			if oldIndex == nil {
				completion(newSections, nil, nil)
				return
			}
		}

	}


}





