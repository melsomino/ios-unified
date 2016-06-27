//
// Created by Michael Vlasov on 24.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public class LayoutWithSingleContent: LayoutItem {
	public var content: LayoutItem!

	// MARK: - LayoutItem

	public override var visible: Bool {
		return content.visible
	}

	public override func traversal(@noescape visit: (LayoutItem) -> Void) {
		super.traversal(visit)
		content.traversal(visit)
	}


}
