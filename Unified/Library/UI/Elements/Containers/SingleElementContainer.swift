//
// Created by Michael Vlasov on 24.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

open class SingleElementContainer: FragmentElement {
	open var child: FragmentElement!

	// MARK: - UiElement

	open override var visible: Bool {
		return child.visible
	}


	open override func traversal(_ visit: (FragmentElement) -> Void) {
		super.traversal(visit)
		child.traversal(visit)
	}


}
