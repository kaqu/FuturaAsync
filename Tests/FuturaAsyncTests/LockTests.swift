import XCTest
@testable import FuturaAsync

class LockTests: XCTestCase {
    
    func testReleasingLockedLock() {
        Lock().lock()
    }
    
    func testLockLock() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            lock.lock()
            DispatchQueueWorker.default.schedule {
                complete()
            }
            lock.lock()
            XCTFail("Lock unlocked while should be locked")
        }
    }
    
    func testLockLockAndUnlock() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            lock.lock()
            DispatchQueueWorker.default.schedule {
                lock.unlock()
            }
            lock.lock()
            complete()
        }
    }
    
    func testLockTryLockSuccess() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            if lock.tryLock() {
                // expected
            } else {
                XCTFail("Lock failed to lock")
            }
            complete()
        }
    }
    
    func testLockTryLockFail() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            lock.lock()
            if lock.tryLock() {
                XCTFail("Lock not failed to lock")
            } else {
                // expected
            }
            complete()
        }
    }
    
    func testLockTimeout() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            lock.lock()
            do {
                try lock.lock(timeout: 1)
                XCTFail("Lock not failed to lock")
            } catch {
                // expected
            }
            complete()
        }
    }
    
    func testLockSynchronized() {
        asyncTest(iterationTimeout: 5, timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            var testValue = 0
            let lock = Lock()
            DispatchQueueWorker.default.schedule {
                sleep(1)
                lock.synchronized {
                    XCTAssert(testValue == 1, "Test value not changed")
                    testValue = -1
                }
            }
            lock.synchronized {
                testValue = 1
                sleep(2)
                XCTAssert(testValue == 1, "Test value changed without synchronization")
            }
            sleep(1)
            lock.synchronized {
                XCTAssert(testValue == -1, "Test value not changed before completing")
            }
            complete()
        }
    }
    
    func testThrowingLockSynchronized() {
        asyncTest(iterationTimeout: 5, timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            do {
                try lock.synchronized {
                    throw "TEST"
                }
                XCTFail("Lock not threw")
            } catch {
                // expected
            }
            complete()
        }
    }
    
    func testLockAndUnlockPerformance() {
        measure {
            let tex = Lock()
            var total = 0
            for _ in 0..<performanceTestIterations {
                tex.lock()
                total += 1
                tex.unlock()
            }
            XCTAssert(total == performanceTestIterations)
        }
    }

    func testLockAndUnlockWithTimeoutPerformance() {
        measure {
            let tex = Lock()
            var total = 0
            for _ in 0..<performanceTestIterations {
                try? tex.lock(timeout: 1)
                total += 1
                tex.unlock()
            }
            XCTAssert(total == performanceTestIterations)
        }

    }
    
    static var allTests = [
        ("testReleasingLockedLock", testReleasingLockedLock),
        ("testLockLock", testLockLock),
        ("testLockLockAndUnlock", testLockLockAndUnlock),
        ("testLockTryLockSuccess", testLockTryLockSuccess),
        ("testLockTryLockFail", testLockTryLockFail),
        ("testLockTimeout", testLockTimeout),
        ("testLockSynchronized", testLockSynchronized),
        ("testThrowingLockSynchronized", testThrowingLockSynchronized),
        ("testLockAndUnlockPerformance", testLockAndUnlockPerformance),
        ("testLockAndUnlockWithTimeoutPerformance", testLockAndUnlockWithTimeoutPerformance),
        ]
}
