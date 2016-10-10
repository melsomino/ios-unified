//
// Created by Michael Vlasov on 24.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation

open class MultipleElementContainer: FragmentElement {

	open var hidden = false
	open var children: [FragmentElement]!


	// MARK: - LayoutItem


	public override required init() {
		super.init()
	}

	open override var visible: Bool {
		if hidden {
			return false
		}
		return children.contains(where: { $0.visible })
	}

	open override var includeInLayout: Bool {
		if hidden && !preserveSpace {
			return false
		}
		return children.contains(where: { $0.includeInLayout })
		
	}
	
	open override func traversal(_ visit: (FragmentElement) -> Void) {
		super.traversal(visit)
		for item in children {
			item.traversal(visit)
		}
	}


	open override func bind(toModel values: [Any?]) {
		super.bind(toModel: values)
		if let boundHidden = definition.boundHidden(values) {
			hidden = boundHidden
		}
	}


}
