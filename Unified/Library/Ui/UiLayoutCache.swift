//
// Created by Michael Vlasov on 02.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit

private class UiFramesByKey {
	var frames = [String: [CGRect]]()
}

public class UiLayoutCache {

	public func clear() {
		cacheByWidth.removeAll(keepCapacity: true)
	}



	public func cachedFramesForWidth(width: CGFloat, key: String) -> [CGRect]? {
		return cacheByWidth[width]?.frames[key]
	}


	public func setFrames(frames: [CGRect], forWidth width: CGFloat, key: String) {
		if let existing = cacheByWidth[width] {
			existing.frames[key] = frames
		}
		else {
			let framesByKey = UiFramesByKey()
			framesByKey.frames[key] = frames
			cacheByWidth[width] = framesByKey
		}
	}


	public func cachedHeightForWidth(width: CGFloat, key: String) -> CGFloat? {
		return cacheByWidth[width]?.frames[key]?[0].height
	}


	// MARK: - Internals


	private var cacheByWidth = [CGFloat: UiFramesByKey]()




}
