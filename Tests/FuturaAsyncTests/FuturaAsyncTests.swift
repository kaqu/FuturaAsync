import XCTest
@testable import FuturaAsync

extension String : Error {}

let testIterations: UInt = 3
let testSemaphore = DispatchSemaphore(value: 1)

extension XCTestCase {
    func asyncTest(iterationTimeout: TimeInterval = 3, iterations: UInt = testIterations, testBody: @escaping (@escaping ()->())->()) {
        
        let testQueue = DispatchQueue(label: "AsyncTestQueue")
        (0..<iterations).forEach { iteration in
            testQueue.async {
                testBody() { testSemaphore.signal() }
            }
            XCTAssert(.success == testSemaphore.wait(timeout: .now() + iterationTimeout), "Not in time - possible deadlock or fail - iteration: \(iteration)")
        }
    }
}

class FuturaAsyncTests: XCTestCase {
    
    func testAsyncBlockPerform() {
        asyncTest { complete in
            async {
                complete()
            }
        }
    }
    
    func testAsyncBlockCatchable() {
        asyncTest { complete in
            let errorToThrow = NSError(domain: "TEST", code: -1, userInfo: nil)
            async {
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

    static var allTests = [
        ("testAsyncBlockPerform", testAsyncBlockPerform),
        ("testAsyncBlockCatchable", testAsyncBlockCatchable),
        ]
}
