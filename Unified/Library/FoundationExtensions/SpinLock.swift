//
// Created by Michael Vlasov on 25.05.16.
//

import Foundation

public struct FastLock {
	var _spinlock = OS_SPINLOCK_INIT

	mutating func lock() {
		OSSpinLockLock(&_spinlock)
	}

	mutating func unlock() {
		OSSpinLockUnlock(&_spinlock)
	}

	mutating func locked<T>(_ action: () -> T) -> T {
		OSSpinLockLock(&_spinlock)
		let result = action()
		OSSpinLockUnlock(&_spinlock)

		return result
	}

	mutating func withLock(_ action: () -> Void) {
		OSSpinLockLock(&_spinlock)
		action()
		OSSpinLockUnlock(&_spinlock)
	}

	mutating func tryLocked<T>(_ action: () -> T) -> T? {
		if !OSSpinLockTry(&_spinlock) {
			return nil
		}

		let result = action()
		OSSpinLockUnlock(&_spinlock)

		return result
	}
}
