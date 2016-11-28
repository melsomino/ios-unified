//
// Created by Michael Vlasov on 25.05.16.
//

import Foundation

public struct FastLock {
	private var _spinlock = OS_SPINLOCK_INIT

	public init() {
	}

	public mutating func lock() {
		OSSpinLockLock(&_spinlock)
	}

	public mutating func unlock() {
		OSSpinLockUnlock(&_spinlock)
	}

	public mutating func locked<T>(_ action: () -> T) -> T {
		OSSpinLockLock(&_spinlock)
		let result = action()
		OSSpinLockUnlock(&_spinlock)

		return result
	}

	public mutating func withLock(_ action: () -> Void) {
		OSSpinLockLock(&_spinlock)
		action()
		OSSpinLockUnlock(&_spinlock)
	}

	public mutating func tryLocked<T>(_ action: () -> T) -> T? {
		if !OSSpinLockTry(&_spinlock) {
			return nil
		}

		let result = action()
		OSSpinLockUnlock(&_spinlock)

		return result
	}
}
