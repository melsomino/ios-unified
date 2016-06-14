//
// Created by Власов М.Ю. on 07.06.16.
// Copyright (c) 2016 Tensor. All rights reserved.
//

import Foundation
import UIKit


public class LabelBack: UIView {

	public override class func layerClass() -> AnyClass {
		return CAGradientLayer.self
	}

	public override func layoutSubviews() {
		super.layoutSubviews()
		guard let gradient = layer as? CAGradientLayer else {
			return
		}
		gradient.startPoint = CGPointMake(0, 0.5)
		gradient.endPoint = CGPointMake(1, 0.5)
		let white = UIColor.whiteColor()
		gradient.colors = [white.colorWithAlphaComponent(0).CGColor, white.CGColor, white.CGColor]
		gradient.locations = [0, bounds.width > 0 ? 20/bounds.width : 0, 1]
	}
}
