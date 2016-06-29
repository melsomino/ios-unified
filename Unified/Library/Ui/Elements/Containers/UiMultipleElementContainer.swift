//
// Created by Michael Vlasov on 24.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public class UiMultipleElementContainer: UiElement {

	public var children: [UiElement]!

	// MARK: - LayoutItem


	public override var visible: Bool {
		return children.contains({ $0.visible })
	}

	public override var fixedSize: Bool {
		return children.contains({ $0.fixedSize })
	}

	public override func traversal(@noescape visit: (UiElement) -> Void) {
		super.traversal(visit)
		for item in children {
			item.traversal(visit)
		}
	}

}
