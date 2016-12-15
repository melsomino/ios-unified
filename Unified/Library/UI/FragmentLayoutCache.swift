//
// Created by Michael Vlasov on 02.06.16.
// Copyright (c) 2016 Michael Vlasov. All rights reserved.
//

import Foundation
import UIKit



fileprivate class CacheForWidth {
	var frames = [String: [CGRect]]()
	var values = [String: [String:
Any]]()
}



public final class FragmentLayoutCache {

	public final func clear() {
		cacheByWidth.removeAll(keepingCapacity: true)
	}



	public final func frames(forWidth width: CGFloat, fragment: String) -> [CGRect]? {
		if let frames = cacheByWidth[width]?.frames[fragment] {
			return frames
		}
		return nil
	}



	public final func height(forWidth width: CGFloat, fragment: String) -> CGFloat? {
		return cacheByWidth[width]?.frames[fragment]?[0].height
	}



	public final func value(forWidth width: CGFloat, fragment: String, element: Int, key: String) -> Any? {
		if let values = cacheByWidth[width]?.values[fragment] {
			return values[FragmentLayoutCache.valueKey(element: element, key: key)]
		}
		return nil
	}



	public final func set(frames: [CGRect], forWidth width: CGFloat, fragment: String) {
		cacheByWidth.getOrAdd(width, CacheForWidth()).frames[fragment] = frames
	}



	public final func set(value: Any, forWidth width: CGFloat, fragment: String, element: Int, key: String) {
		let valueKey = FragmentLayoutCache.valueKey(element: element, key: key)
		let cache = cacheByWidth.getOrAdd(width, CacheForWidth())
		var values = cache.values[fragment] ?? [String:Any]()
		values[valueKey] = value
		cache.values[fragment] = values
	}






	public init() {
	}



	public final func dropFrames(forFragment fragment: String) {
		for (_, cache) in cacheByWidth {
			cache.frames.removeValue(forKey: fragment)
		}
	}

	// MARK: - Internals


	private var cacheByWidth = [CGFloat: CacheForWidth]()

	private static func valueKey(element: Int, key: String) -> String {
		return "\(element).\(key)"
	}


}
