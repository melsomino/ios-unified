//
// Created by Michael Vlasov on 01.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit


public class LayoutItem {

	public var id: String?

	public var visible: Bool {
		return true
	}

	public var fixedSize: Bool {
		return false
	}

	public func traversal(@noescape visit: (LayoutItem) -> Void) {
		visit(self)
	}

	public func measureMaxSize(bounds: CGSize) -> CGSize {
		return bounds
	}

	public func measureSize(bounds: CGSize) -> CGSize {
		return bounds
	}

	public func layout(bounds: CGRect) -> CGRect {
		return bounds
	}



}
