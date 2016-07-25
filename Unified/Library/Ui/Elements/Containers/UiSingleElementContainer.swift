//
// Created by Michael Vlasov on 24.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public class UiSingleElementContainer: UiElement {
	public var child: UiElement!

	// MARK: - UiElement

	public override var visible: Bool {
		return child.visible
	}


	public override func traversal(@noescape visit: (UiElement) -> Void) {
		super.traversal(visit)
		child.traversal(visit)
	}


}
