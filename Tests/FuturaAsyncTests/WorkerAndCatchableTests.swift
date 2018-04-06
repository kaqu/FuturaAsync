import XCTest
@testable import FuturaAsync

class WorkerAndCatchableTests: XCTestCase {
    static var allTests:[(String, (WorkerAndCatchableTests)->()->())] = []

    #if os(macOS)
    func testDispatchQueueWorkerQueue() {
        XCTAssert(DispatchQueueWorker.main.queue == .main, "Main worker is not main queue")
        XCTAssert(DispatchQueueWorker.default.queue == .global(qos: .default), "Default worker is not default queue")
        XCTAssert(DispatchQueueWorker.utility.queue == .global(qos: .utility), "Utility worker is not utility queue")
        XCTAssert(DispatchQueueWorker.background.queue == .global(qos: .background), "Background worker is not background queue")
        let testQueue = DispatchQueue(label: "TestQueue")
        XCTAssert(DispatchQueueWorker.custom(testQueue).queue == testQueue, "Custom worker is not custom queue")
    }
    #endif

    func testWorkerClosurePerform() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let worker: Worker = DispatchQueueWorker.default
            worker.schedule { () -> Void in
                complete()
            }
        }
    }

    func testThrowingWorkerClosurePerform() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let worker: Worker = DispatchQueueWorker.default
            worker.schedule { () throws -> Void in
                complete()
            }
        }
    }

    func testWorkerClosurePerformWithCatchable() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let errorToThrow = "ERR"
            let worker: Worker = DispatchQueueWorker.default
            worker.schedule {
                throw errorToThrow
                }
                .catch { error in
                    defer { complete() }
                    guard error as? String == errorToThrow else {
                        XCTFail("Not failed with proper error")
                        return
                    }
            }
        }
    }

    func testWorkerClosurePerformWithCatchableMemoryReleaseWithoutError() {
        asyncTest(iterationTimeout: 4, timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            lock.lock()
            let worker: Worker = DispatchQueueWorker.default
            weak var catchable: Catchable? = worker.schedule { sleep(2) ; lock.unlock() }
            sleep(1)
            XCTAssert(catchable != nil, "Released to early")
            lock.lock()
            sleep(1) // wait for async release
            XCTAssert(catchable == nil, "Not released at all")
            complete()
        }
    }

    func testWorkerClosurePerformWithCatchableMemoryReleaseOnError() {
        asyncTest(iterationTimeout: 5, timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let lock = Lock()
            lock.lock()
            let worker: Worker = DispatchQueueWorker.default
            weak var catchable: Catchable? = worker.schedule { sleep(2) ; throw "ERR" }
            catchable?.catch { _ in lock.unlock() }
            sleep(1)
            XCTAssert(catchable != nil, "Released to early")
            lock.lock()
            sleep(2) // wait for release
            XCTAssert(catchable == nil, "Not released at all")
            complete()
        }
    }

    func testCatchableDoubleCompleteWithCompletion() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let catchable = Catchable()
            catchable.close()
            catchable.handle(error: "ERR")
            catchable.catch { _ in XCTFail("No error - should not call at all") }
            complete()
        }
    }

    func testCatchableHandlerAfterCompletion() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let errorToCheck = "ERR"
            let catchable = Catchable()
            catchable.handle(error: errorToCheck)
            catchable.catch { error in
                defer { complete() }
                guard error as? String == errorToCheck else {
                    XCTFail("Not failed with proper error")
                    return
                }
            }
        }
    }
    
    static var allTests = [
        ("testWorkerClosurePerform", testWorkerClosurePerform),
        ("testThrowingWorkerClosurePerform", testThrowingWorkerClosurePerform),
        ("testWorkerClosurePerformWithCatchable", testWorkerClosurePerformWithCatchable),
        ("testWorkerClosurePerformWithCatchableMemoryReleaseWithoutError", testWorkerClosurePerformWithCatchableMemoryReleaseWithoutError),
        ("testWorkerClosurePerformWithCatchableMemoryReleaseOnError", testWorkerClosurePerformWithCatchableMemoryReleaseOnError),
        ("testCatchableDoubleCompleteWithCompletion", testCatchableDoubleCompleteWithCompletion),
        ("testCatchableHandlerAfterCompletion", testCatchableHandlerAfterCompletion),
        ]
}

