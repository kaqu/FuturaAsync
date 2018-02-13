import XCTest
@testable import FuturaAsync

class WorkerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Worker.applicationDefault = .main
    }
    
    func testWokrerQueues() {
        XCTAssert(Worker.applicationDefault.queue == .main, "Application default worker is not main queue")
        XCTAssert(Worker.main.queue == .main, "Main worker is not main queue")
        XCTAssert(Worker.default.queue == .global(qos: .default), "Default worker is not default queue")
        XCTAssert(Worker.utility.queue == .global(qos: .utility), "Utility worker is not utility queue")
        XCTAssert(Worker.background.queue == .global(qos: .background), "Background worker is not background queue")
        let testQueue = DispatchQueue(label: "TestQueue")
        XCTAssert(Worker.custom(testQueue).queue == testQueue, "Custom worker is not custom queue")
    }
    
    func testWorkerClosurePerform() {
        asyncTest { complete in
            Worker.default.schedule {
                complete()
            }
        }
    }
    
    func testWorkerClosurePerformWithCatchable() {
        asyncTest(iterationTimeout: 3) { complete in
            let errorToThrow = NSError(domain: "TEST", code: -1, userInfo: nil)
            Worker.default.schedule {
                throw errorToThrow
                }
                .catch { error in
                    defer { complete() }
                    guard error as NSError == errorToThrow else {
                        XCTFail("Not failed with proper error")
                        return
                    }
            }
        }
    }
    
    func testWorkerClosurePerformWithCatchableMemoryReleaseWithoutError() {
        asyncTest(iterationTimeout: 6) { complete in
            let syncPromise = Promise<Void>()
            weak var catchable: Catchable? = Worker.default.schedule { sleep(2) ; try? syncPromise.fulfill(with: Void()) }
            sleep(1)
            XCTAssert(catchable != nil, "Released to early")
            try? syncPromise.future.await()
            sleep(1) // wait for async release
            XCTAssert(catchable == nil, "Not released at all")
            complete()
        }
    }
    
    func testWorkerClosurePerformWithCatchableMemoryReleaseOnError() {
        asyncTest(iterationTimeout: 7) { complete in
            let syncPromise = Promise<Void>()
            weak var catchable: Catchable? = Worker.default.schedule { sleep(2) ; throw NSError() }
            catchable?.catch { _ in try? syncPromise.fulfill(with: Void()) }
            sleep(1)
            XCTAssert(catchable != nil, "Released to early")
            try? syncPromise.future.await()
            sleep(2) // wait for release
            XCTAssert(catchable == nil, "Not released at all")
            complete()
        }
    }
    
    func testDelayedWorkerClosurePerform() {
        asyncTest(iterationTimeout: 3) { complete in
            Worker.default.schedule(after: 1) {
                complete()
            }
        }
    }
    
    func testDelayedWorkerClosurePerformWithCatchable() {
        asyncTest(iterationTimeout: 4) { complete in
            let errorToThrow = NSError(domain: "TEST", code: -1, userInfo: nil)
            Worker.default.schedule(after: 1) {
                throw errorToThrow
                }
                .catch { error in
                    defer { complete() }
                    guard error as NSError == errorToThrow else {
                        XCTFail("Not failed with proper error")
                        return
                    }
            }
        }
    }
    
    func testDelayedWorkerClosurePerformWithCatchableMemoryReleaseWithoutError() {
        asyncTest(iterationTimeout: 7) { complete in
            let syncPromise = Promise<Void>()
            weak var catchable: Catchable? = Worker.default.schedule(after: 1) { sleep(2) ; try? syncPromise.fulfill(with: Void()) }
            sleep(1)
            XCTAssert(catchable != nil, "Released to early")
            try? syncPromise.future.await()
            sleep(1) // wait for async release
            XCTAssert(catchable == nil, "Not released at all")
            complete()
        }
    }
    
    func testDelayedWorkerClosurePerformWithCatchableMemoryReleaseOnError() {
        asyncTest(iterationTimeout: 7) { complete in
            let syncPromise = Promise<Void>()
            weak var catchable: Catchable? = Worker.default.schedule(after: 1) { sleep(2) ; throw NSError() }
            sleep(1)
            XCTAssert(catchable != nil, "Released to early")
            catchable?.catch { _ in try? syncPromise.fulfill(with: Void()) }
            try? syncPromise.future.await()
            sleep(1) // wait for async release
            XCTAssert(catchable == nil, "Not released at all")
            complete()
        }
    }
    
    func testCatchableDoubleCompleteWithCompletion() {
        asyncTest { complete in
            let catchable = Catchable()
            catchable.complete(with: nil)
            catchable.complete(with: NSError())
            catchable.catch { _ in XCTFail("No error - should not call at all") }
            complete()
        }
    }
    
    func testCatchableHandlerAfterCompletion() {
        asyncTest { complete in
            let errorToCheck = NSError(domain: "TEST", code: -1, userInfo: nil)
            let catchable = Catchable()
            catchable.complete(with: errorToCheck)
            catchable.catch { error in
                defer { complete() }
                guard error as NSError == errorToCheck else {
                    XCTFail("Not failed with proper error")
                    return
                }
            }
        }
    }

    static var allTests = [
        ("testWokrerQueues", testWokrerQueues),
        ("testWorkerClosurePerform", testWorkerClosurePerform),
        ("testWorkerClosurePerformWithCatchable", testWorkerClosurePerformWithCatchable),
        ("testWorkerClosurePerformWithCatchableMemoryReleaseWithoutError", testWorkerClosurePerformWithCatchableMemoryReleaseWithoutError),
        ("testWorkerClosurePerformWithCatchableMemoryReleaseOnError", testWorkerClosurePerformWithCatchableMemoryReleaseOnError),
        ("testDelayedWorkerClosurePerform", testDelayedWorkerClosurePerform),
        ("testDelayedWorkerClosurePerformWithCatchable", testDelayedWorkerClosurePerformWithCatchable),
        ("testDelayedWorkerClosurePerformWithCatchableMemoryReleaseWithoutError", testDelayedWorkerClosurePerformWithCatchableMemoryReleaseWithoutError),
        ("testDelayedWorkerClosurePerformWithCatchableMemoryReleaseOnError", testDelayedWorkerClosurePerformWithCatchableMemoryReleaseOnError),
        ("testCatchableDoubleCompleteWithCompletion", testCatchableDoubleCompleteWithCompletion),
        ("testCatchableHandlerAfterCompletion", testCatchableHandlerAfterCompletion),
        ]
}
