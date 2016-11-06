//
// Created by Michael Vlasov on 25.05.16.
//

import Foundation

open class ListenerList<ListenerType> {

	public init() {

	}



	open func add(_ listener: ListenerType) {
		lock.lock()
		items.add(listener as AnyObject)
		lock.unlock()
	}



	open func remove(_ listener: ListenerType) {
		lock.lock()
		items.remove(listener as AnyObject)
		lock.unlock()
	}



	open func getLive() -> [ListenerType] {
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

	private let items = NSHashTable<AnyObject>.weakObjects()
	private var lock = FastLock()


}
