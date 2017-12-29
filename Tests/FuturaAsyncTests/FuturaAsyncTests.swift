import XCTest
@testable import FuturaAsync

extension String : Error {}

let testIterations: UInt = 3

extension XCTestCase {
    func asyncTest(iterationTimeout: TimeInterval = 2, iterations: UInt = testIterations, testBody: @escaping (@escaping ()->())->()) {
        let testSemaphore = DispatchSemaphore(value: 1)
        let testQueue = DispatchQueue(label: "AsyncTestQueue")
        (0...iterations).forEach { iteration in
            testQueue.async {
                testBody() {
                    testSemaphore.signal()
                }
            }
            XCTAssert(.success == testSemaphore.wait(timeout: .now() + iterationTimeout), "Not in time - possible deadlock or fail - iteration: \(iteration)")
        }
    }
}

class FuturaAsyncTests: XCTestCase {
    
    // TODO: tests - Future/Promise
    // - memory management - check if releasing memory properly
    // - race condition - mulithreaded read/write

}
