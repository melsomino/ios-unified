//
// Created by Michael Vlasov on 02.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

private class FragmentFramesByKey {
	var frames = [String: [CGRect]]()
}

open class FragmentLayoutCache {

	open func clear() {
		cacheByWidth.removeAll(keepingCapacity: true)
	}



	open func cachedFramesForWidth(_ width: CGFloat, key: String) -> [CGRect]? {
		return cacheByWidth[width]?.frames[key]
	}


	open func setFrames(_ frames: [CGRect], forWidth width: CGFloat, key: String) {
		if let existing = cacheByWidth[width] {
			existing.frames[key] = frames
		}
		else {
			let framesByKey = FragmentFramesByKey()
			framesByKey.frames[key] = frames
			cacheByWidth[width] = framesByKey
		}
	}


	open func cachedHeightForWidth(_ width: CGFloat, key: String) -> CGFloat? {
		return cacheByWidth[width]?.frames[key]?[0].height
	}

	public init() {
	}

	public final func drop(cacheForKey key: String) {
		for (_, frames) in cacheByWidth {
			frames.frames.removeValue(forKey: key)
		}
	}

	// MARK: - Internals


	fileprivate var cacheByWidth = [CGFloat: FragmentFramesByKey]()




}
