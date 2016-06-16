//
// Created by Michael Vlasov on 15.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

public class LayoutWithModel<Model>: Layout {
	public private(set) var model: Model!

	public func setModel(model: Model) {
		self.model = model
		reflectLayout()
		if boundToViews {
			reflectViews()
		}
	}

	public required init(inSuperview superview: UIView?) {
		super.init(inSuperview: superview)
	}

	// MARK: - Virtuals


	public func reflectLayout() {
	}


	public func reflectViews() {
	}


}
