//
// Created by Michael Vlasov on 06.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation


private enum AnimationStage {
	case prepareToShow, animateShow, animateHide, completeHide
}


class CentralUIAnimations {

	private static let duration = TimeInterval(0.25)

	static func contentTransition(from oldController: UIViewController?, to newController: UIViewController?,
		containerController: UIViewController, containerView: UIView, animation: CentralUIContentAnimation, completion: (() -> Void)? = nil) {

		guard newController != oldController else {
			return
		}

		let bounds = containerView.bounds

		if oldController != nil {
			oldController!.willMove(toParentViewController: nil)
		}
		if newController != nil {
			containerController.addChildViewController(newController!)
			animationStage(.prepareToShow, newController!.view, bounds, animation)
			containerView.addSubview(newController!.view)
		}

		if animation == .none {
			if oldController != nil {
				oldController!.removeFromParentViewController()
				oldController!.view.removeFromSuperview()
			}
			if newController != nil {
				newController!.didMove(toParentViewController: containerController)
			}
			completion?()
			return
		}

		UIView.animate(withDuration: duration,
			animations: {
				if oldController != nil {
					animationStage(.animateHide, oldController!.view, bounds, animation)
				}
				if newController != nil {
					animationStage(.animateShow, newController!.view, bounds, animation)
				}
			},
			completion: {
				finished in
				if oldController != nil {
					animationStage(.completeHide, oldController!.view, bounds, animation)
					oldController!.removeFromParentViewController()
					oldController!.view.removeFromSuperview()
				}
				if newController != nil {
					newController!.didMove(toParentViewController: containerController)
				}
				completion?()
			})
	}


	private static func animationStage(_ stage: AnimationStage, _ view: UIView, _ bounds: CGRect, _ animation: CentralUIContentAnimation) {
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


	private static func fadeAnimation(_ stage: AnimationStage, _ view: UIView, _ bounds: CGRect) {
		switch stage {
			case .prepareToShow:
				view.frame = bounds
				view.alpha = 0
				break;
			case .animateShow:
				view.alpha = 1
				break;
			case .animateHide:
				view.alpha = 0
				break;
			case .completeHide:
				view.alpha = 1
				break;
		}
	}


	private static func fromDownAnimation(_ stage: AnimationStage, _ view: UIView, _ bounds: CGRect) {
		switch stage {
			case .prepareToShow:
				view.frame = bounds.offsetBy(dx: 0, dy: bounds.size.height)
				break;
			case .animateShow:
				view.frame = bounds
				break;
			case .animateHide:
				view.frame = bounds.offsetBy(dx: 0, dy: -bounds.size.height)
				break;
			case .completeHide:
				break;
		}
	}

	private static func fromUpAnimation(_ stage: AnimationStage, _ view: UIView, _ bounds: CGRect) {
		switch stage {
			case .prepareToShow:
				view.frame = bounds.offsetBy(dx: 0, dy: -bounds.size.height)
				break;
			case .animateShow:
				view.frame = bounds
				break;
			case .animateHide:
				view.frame = bounds.offsetBy(dx: 0, dy: bounds.size.height)
				break;
			case .completeHide:
				break;
		}
	}

	private static func noneAnimation(_ stage: AnimationStage, _ view: UIView, _ bounds: CGRect) {
		switch stage {
			case .prepareToShow:
				view.frame = bounds
				break;
			case .animateShow:
				break;
			case .animateHide:
				break;
			case .completeHide:
				break;
		}
	}


}
