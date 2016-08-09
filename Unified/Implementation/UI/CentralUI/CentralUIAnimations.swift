//
// Created by Michael Vlasov on 06.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation


private enum AnimationStage {
	case PrepareToShow, AnimateShow, AnimateHide, CompleteHide
}


class CentralUIAnimations {

	private static let duration = NSTimeInterval(0.25)

	static func contentTransition(from oldController: UIViewController?, to newController: UIViewController?,
		containerController: UIViewController, containerView: UIView, animation: CentralUIContentAnimation, completion: (() -> Void)? = nil) {

		guard newController != oldController else {
			return
		}

		let bounds = containerView.bounds

		if oldController != nil {
			oldController!.willMoveToParentViewController(nil)
		}
		if newController != nil {
			containerController.addChildViewController(newController!)
			animationStage(.PrepareToShow, newController!.view, bounds, animation)
			containerView.addSubview(newController!.view)
		}

		if animation == .None {
			if oldController != nil {
				oldController!.removeFromParentViewController()
				oldController!.view.removeFromSuperview()
			}
			if newController != nil {
				newController!.didMoveToParentViewController(containerController)
			}
			completion?()
			return
		}

		UIView.animateWithDuration(duration,
			animations: {
				if oldController != nil {
					animationStage(.AnimateHide, oldController!.view, bounds, animation)
				}
				if newController != nil {
					animationStage(.AnimateShow, newController!.view, bounds, animation)
				}
			},
			completion: {
				finished in
				if oldController != nil {
					animationStage(.CompleteHide, oldController!.view, bounds, animation)
					oldController!.removeFromParentViewController()
					oldController!.view.removeFromSuperview()
				}
				if newController != nil {
					newController!.didMoveToParentViewController(containerController)
				}
				completion?()
			})
	}


	private static func animationStage(stage: AnimationStage, _ view: UIView, _ bounds: CGRect, _ animation: CentralUIContentAnimation) {
		switch animation {
			case .fade:
				fadeAnimation(stage, view, bounds)
				break
			case .fromDown:
				fromDownAnimation(stage, view, bounds)
				break
			case .fromUp:
				fromUpAnimation(stage, view, bounds)
				break
			default:
				noneAnimation(stage, view, bounds)
				break
		}
	}


	private static func fadeAnimation(stage: AnimationStage, _ view: UIView, _ bounds: CGRect) {
		switch stage {
			case .PrepareToShow:
				view.frame = bounds
				view.alpha = 0
				break;
			case .AnimateShow:
				view.alpha = 1
				break;
			case .AnimateHide:
				view.alpha = 0
				break;
			case .CompleteHide:
				view.alpha = 1
				break;
		}
	}


	private static func fromDownAnimation(stage: AnimationStage, _ view: UIView, _ bounds: CGRect) {
		switch stage {
			case .PrepareToShow:
				view.frame = CGRectOffset(bounds, 0, bounds.size.height)
				break;
			case .AnimateShow:
				view.frame = bounds
				break;
			case .AnimateHide:
				view.frame = CGRectOffset(bounds, 0, -bounds.size.height)
				break;
			case .CompleteHide:
				break;
		}
	}

	private static func fromUpAnimation(stage: AnimationStage, _ view: UIView, _ bounds: CGRect) {
		switch stage {
			case .PrepareToShow:
				view.frame = CGRectOffset(bounds, 0, -bounds.size.height)
				break;
			case .AnimateShow:
				view.frame = bounds
				break;
			case .AnimateHide:
				view.frame = CGRectOffset(bounds, 0, bounds.size.height)
				break;
			case .CompleteHide:
				break;
		}
	}

	private static func noneAnimation(stage: AnimationStage, _ view: UIView, _ bounds: CGRect) {
		switch stage {
			case .PrepareToShow:
				view.frame = bounds
				break;
			case .AnimateShow:
				break;
			case .AnimateHide:
				break;
			case .CompleteHide:
				break;
		}
	}


}
