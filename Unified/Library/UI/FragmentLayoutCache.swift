//
// Created by Michael Vlasov on 02.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit



fileprivate class FragmentElements {
	var byIndex = [Int: [String:
Any]]()
}



fileprivate class Fragments {
	var framesByKey = [String: [CGRect]]()
	var elementsByKey = [String: FragmentElements]()
}



public final class FragmentLayoutCache {

	public final func clear() {
		byWidth.removeAll(keepingCapacity: true)
	}



	public final func cachedFramesForWidth(_ width: CGFloat, key: String) -> [CGRect]? {
		return byWidth[width]?.framesByKey[key]
	}



	public final func valueFor(width: CGFloat, fragment: String, element: Int, key: String) -> Any? {
		if let fragments = byWidth[width],
		   let elements = fragment.elementsByKey[fragment],
		   let values = elements.byIndex[element],
		   let value = values[key] {
			return value
		}
		return nil
	}



	public final func set(value: Any, forWidth width: CGFloat, fragment: String, element: Int, key: String) {
		if let existing = byWidth[width] {
			existing.frames[key] = frames
		}
		else {
			let framesByKey = FragmentFramesByKey()
			framesByKey.frames[key] = frames
			byWidth[width] = framesByKey
		}
	}



	public final func setFrames(_ frames: [CGRect], forWidth width: CGFloat, key: String) {
		if let existing = byWidth[width] {
			existing.frames[key] = frames
		}
		else {
			let framesByKey = FragmentFramesByKey()
			framesByKey.frames[key] = frames
			byWidth[width] = framesByKey
		}
	}



	public final func cachedHeightForWidth(_ width: CGFloat, key: String) -> CGFloat? {
		return byWidth[width]?.frames[key]?[0].height
	}



	public init() {
	}



	public final func drop(cacheForKey key: String) {
		for (_, fragments) in byWidth {
			fragments.frames.removeValue(forKey: key)
			fragments.values.removeValue(forKey: key)
		}
	}

	// MARK: - Internals


	private var byWidth = [CGFloat: FragmentFramesByKey]()


}
