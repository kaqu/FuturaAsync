import XCTest
@testable import FuturaAsync

class FuturaAsyncTests: XCTestCase {

    func testGlobalSchedulePerform() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            schedule { () -> Void in
                complete()
            }
        }
    }
    
    func testThrowingGlobalSchedulePerform() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            schedule { () throws -> Void in
                complete()
            }
        }
    }

    func testThrowingGlobalScheduleWithCatchable() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let errorToThrow = "TEST"
            schedule { throw errorToThrow }
            .catch { error in
                defer { complete() }
                guard error as? String == errorToThrow else {
                    XCTFail("Not failed with proper error")
                    return
                }
            }
        }
    }
}

// MARK: test extensions

let performanceTestIterations = 10_000_000

extension String : Error {}

extension XCTestCase {
    
    func asyncTest(iterationTimeout: TimeInterval = 3, iterations: UInt = 1, timeoutBody: @escaping ()->(), testBody: @escaping (@escaping ()->())->()) {
        let mtx = Lock()
        let testQueue = DispatchQueue(label: "AsyncTestQueue")
        (0..<iterations).forEach { iteration in
            testQueue.async {
                mtx.lock()
                testBody() { mtx.unlock() }
            }
            do {
                try mtx.lock(timeout: UInt8(iterationTimeout))
            } catch {
                timeoutBody()
            }
        }
    }
}
