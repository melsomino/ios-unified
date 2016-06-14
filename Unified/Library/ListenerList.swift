//
// Created by Власов М.Ю. on 25.05.16.
//

import Foundation

public class ListenerList<ListenerType> {

	public func add(listener: ListenerType) {
		guard let object = listener as? AnyObject else {
			fatalError("Object (\(listener)) should be subclass of AnyObject")
		}
		lock.lock()
		items.addObject(object)
		lock.unlock()
	}



	public func remove(listener: ListenerType) {
		guard let object = listener as? AnyObject else {
			fatalError("Object (\(listener)) should be subclass of AnyObject")
		}
		lock.lock()
		items.removeObject(object)
		lock.unlock()
	}

	public func getLive() -> [ListenerType] {
		var live = [ListenerType]()
		lock.lock()
		for item in items.objectEnumerator() {
			if let listener = item as? ListenerType {
				live.append(listener)
			}
		}
		lock.unlock()
		return live
	}

	private let items = NSHashTable.weakObjectsHashTable()
	private var lock = FastLock()


}
