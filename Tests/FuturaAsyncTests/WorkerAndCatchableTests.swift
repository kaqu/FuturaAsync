import XCTest
@testable import FuturaAsync

class WorkerAndCatchableTests: XCTestCase {
    static var allTests:[(String, (WorkerAndCatchableTests)->()->())] = []
}

//
//    override func setUp() {
//        super.setUp()
//    }
//    
//    func testDispatchQueueWorkerQueue() {
//        XCTAssert(DispatchQueueWorker.main.queue == .main, "Main worker is not main queue")
//        XCTAssert(DispatchQueueWorker.default.queue == .global(qos: .default), "Default worker is not default queue")
//        XCTAssert(DispatchQueueWorker.utility.queue == .global(qos: .utility), "Utility worker is not utility queue")
//        XCTAssert(DispatchQueueWorker.background.queue == .global(qos: .background), "Background worker is not background queue")
//        let testQueue = DispatchQueue(label: "TestQueue")
//        XCTAssert(DispatchQueueWorker.custom(testQueue).queue == testQueue, "Custom worker is not custom queue")
//    }
//    
//    func testWorkerClosurePerform() {
//        asyncTest(timeoutBody: {
//            XCTFail("Not in time - possible deadlock or fail")
//        })
//        { complete in
//            let worker: Worker = DispatchQueueWorker.default
//            worker.schedule { () -> Void in
//                complete()
//            }
//        }
//    }
//    
//    func testThrowingWorkerClosurePerform() {
//        asyncTest(timeoutBody: {
//            XCTFail("Not in time - possible deadlock or fail")
//        })
//        { complete in
//            let worker: Worker = DispatchQueueWorker.default
//            worker.schedule { () throws -> Void in
//                complete()
//            }
//        }
//    }
//    
//    func testWorkerClosurePerformWithCatchable() {
//        asyncTest(timeoutBody: {
//            XCTFail("Not in time - possible deadlock or fail")
//        })
//        { complete in
//            let errorToThrow = NSError(domain: "TEST", code: -1, userInfo: nil)
//            let worker: Worker = DispatchQueueWorker.default
//            worker.schedule {
//                throw errorToThrow
//                }
//                .catch { error in
//                    defer { complete() }
//                    guard error as NSError == errorToThrow else {
//                        XCTFail("Not failed with proper error")
//                        return
//                    }
//            }
//        }
//    }
//    
//    func testWorkerClosurePerformWithCatchableMemoryReleaseWithoutError() {
//        asyncTest(iterationTimeout: 4, timeoutBody: {
//            XCTFail("Not in time - possible deadlock or fail")
//        })
//        { complete in
//            let mtx = Mutex()
//            mtx.lock()
//            let worker: Worker = DispatchQueueWorker.default
//            weak var catchable: Catchable? = worker.schedule { sleep(2) ; mtx.unlock() }
//            sleep(1)
//            XCTAssert(catchable != nil, "Released to early")
//            mtx.lock()
//            sleep(1) // wait for async release
//            XCTAssert(catchable == nil, "Not released at all")
//            complete()
//        }
//    }
//    
//    func testWorkerClosurePerformWithCatchableMemoryReleaseOnError() {
//        asyncTest(iterationTimeout: 5, timeoutBody: {
//            XCTFail("Not in time - possible deadlock or fail")
//        })
//        { complete in
//            let mtx = Mutex()
//            mtx.lock()
//            let worker: Worker = DispatchQueueWorker.default
//            weak var catchable: Catchable? = worker.schedule { sleep(2) ; throw NSError() }
//            catchable?.catch { _ in mtx.unlock() }
//            sleep(1)
//            XCTAssert(catchable != nil, "Released to early")
//            mtx.lock()
//            sleep(2) // wait for release
//            XCTAssert(catchable == nil, "Not released at all")
//            complete()
//        }
//    }
//    
//    func testCatchableDoubleCompleteWithCompletion() {
//        asyncTest(timeoutBody: {
//            XCTFail("Not in time - possible deadlock or fail")
//        })
//        { complete in
//            let catchable = Catchable()
//            catchable.complete(with: nil)
//            catchable.complete(with: NSError())
//            catchable.catch { _ in XCTFail("No error - should not call at all") }
//            complete()
//        }
//    }
//    
//    func testCatchableHandlerAfterCompletion() {
//        asyncTest(timeoutBody: {
//            XCTFail("Not in time - possible deadlock or fail")
//        })
//        { complete in
//            let errorToCheck = NSError(domain: "TEST", code: -1, userInfo: nil)
//            let catchable = Catchable()
//            catchable.complete(with: errorToCheck)
//            catchable.catch { error in
//                defer { complete() }
//                guard error as NSError == errorToCheck else {
//                    XCTFail("Not failed with proper error")
//                    return
//                }
//            }
//        }
//    }
//}
//
