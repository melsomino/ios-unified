//
// Created by Michael Vlasov on 25.05.16.
//

import Foundation

open class ListenerList<ListenerType> {

	public init() {

	}



	open func add(_ listener: ListenerType) {
		guard let object = listener as? AnyObject else {
			fatalError("Object (\(listener)) should be subclass of AnyObject (ListenerList.add)")
		}
		lock.lock()
		items.add(object)
		lock.unlock()
	}



	open func remove(_ listener: ListenerType) {
		guard let object = listener as? AnyObject else {
			fatalError("Object (\(listener)) should be subclass of AnyObject (ListenerList.remove)")
		}
		lock.lock()
		items.remove(object)
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
