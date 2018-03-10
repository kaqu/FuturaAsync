import XCTest
@testable import FuturaAsync

class MutexTests: XCTestCase {
    
    func testReleasingLockedMutex() {
        Mutex().lock()
    }
    
    func testMutexLock() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let mutex = Mutex()
            mutex.lock()
            DispatchQueueWorker.default.schedule {
                complete()
            }
            mutex.lock()
            XCTFail("Mutex unlocked while should be locked")
        }
    }
    
    func testMutexLockAndUnlock() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let mutex = Mutex()
            mutex.lock()
            DispatchQueueWorker.default.schedule {
                mutex.unlock()
            }
            mutex.lock()
            complete()
        }
    }
    
    func testMutexTryLockSuccess() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let mutex = Mutex()
            if mutex.tryLock() {
                // expected
            } else {
                XCTFail("Mutex failed to lock")
            }
            complete()
        }
    }
    
    func testMutexTryLockFail() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let mutex = Mutex()
            mutex.lock()
            if mutex.tryLock() {
                XCTFail("Mutex not failed to lock")
            } else {
                // expected
            }
            complete()
        }
    }
    
    func testMutexTimeout() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let mutex = Mutex()
            mutex.lock()
            do {
                try mutex.lock(timeout: 1)
                XCTFail("Mutex not failed to lock")
            } catch {
                // expected
            }
            complete()
        }
    }
    
    func testMutexSynchronized() {
        asyncTest(iterationTimeout: 5, timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            var testValue = 0
            let mutex = Mutex()
            DispatchQueueWorker.default.schedule {
                sleep(1)
                mutex.synchronized {
                    XCTAssert(testValue == 1, "Test value not changed")
                    testValue = -1
                }
            }
            mutex.synchronized {
                testValue = 1
                sleep(2)
                XCTAssert(testValue == 1, "Test value changed without synchronization")
            }
            sleep(1)
            mutex.synchronized {
                XCTAssert(testValue == -1, "Test value not changed before completing")
            }
            complete()
        }
    }
    
    func testThrowingMutexSynchronized() {
        asyncTest(iterationTimeout: 5, timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let mutex = Mutex()
            do {
                try mutex.synchronized {
                    throw "TEST"
                }
                XCTFail("Mutex not threw")
            } catch {
                // expected
            }
            complete()
        }
    }
    
    func testLockAndUnlockPerformance() {
        measure {
            let tex = Mutex()
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
            let tex = Mutex()
            var total = 0
            for _ in 0..<performanceTestIterations {
                try? tex.lock(timeout: 1)
                total += 1
                tex.unlock()
            }
            XCTAssert(total == performanceTestIterations)
        }

    }
}
