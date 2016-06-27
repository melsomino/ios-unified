//
// Created by Michael Vlasov on 24.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public class LayoutWithMultipleContent: LayoutItem {

	public var content: [LayoutItem]!

	// MARK: - LayoutItem


	public override var visible: Bool {
		return content.contains({ $0.visible })
	}

	public override var fixedSize: Bool {
		return content.contains({ $0.fixedSize })
	}

	public override func traversal(@noescape visit: (LayoutItem) -> Void) {
		super.traversal(visit)
		for item in content {
			item.traversal(visit)
		}
	}

}
