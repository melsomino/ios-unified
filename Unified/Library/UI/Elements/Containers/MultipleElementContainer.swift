//
// Created by Michael Vlasov on 24.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

public class MultipleElementContainer: FragmentElement {

	public var hidden = false
	public var children: [FragmentElement]!


	// MARK: - LayoutItem

	public override required init() {
		super.init()
	}

	public override var visible: Bool {
		if hidden {
			return false
		}
		return children.contains({ $0.visible })
	}

	public override func traversal(@noescape visit: (FragmentElement) -> Void) {
		super.traversal(visit)
		for item in children {
			item.traversal(visit)
		}
	}

}
