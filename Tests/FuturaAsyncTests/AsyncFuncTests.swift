import XCTest
import FuturaFunc
@testable import FuturaAsync

class AsyncFuncTests: XCTestCase {
    
    func testSyncApplication() {
        asyncTest { complete in
            let promise = Promise<String>()
            DispatchQueue.global().async {
                sleep(1)
                try? promise.fulfill(with: "TEST")
            }
            let future = promise.future
            do {
                let value: String = try future ||> String.lowercased^
                XCTAssert(value == "test", "Future value not matching: expected-\(Void()), provided-\(value)")
            } catch {
                XCTFail("Future failed with error - \(error)")
            }
            complete()
        }
    }
    
    func testAsyncApplication() {
        asyncTest { complete in
            let promise = Promise<String>()
            DispatchQueue.global().async {
                sleep(1)
                try? promise.fulfill(with: "TEST")
            }
            let future = promise.future
            async {
                let value: String = try future ||> String.lowercased^
                XCTAssert(value == "test", "Future value not matching: expected-\(Void()), provided-\(value)")
                complete()
            }
            .catch { error in
                XCTFail("Future failed with error - \(error)")
                complete()
            }
        }
    }
    
    func testAsyncResultAlternativeSuccess() {
        asyncTest { complete in
            let promise = Promise<String>()
            DispatchQueue.global().async {
                sleep(1)
                try? promise.fail(with: "TEST")
            }
            let future = promise.future
            async {
                try future
                    ||>
                    String.lowercased^ >>> { _ in XCTFail("Future not failed") }
                    <||>
                    { XCTAssert($0 as? String == "TEST", "Future error not matching: expected-\(Void()), provided-\($0)") }
                complete()
            }
            .catch { error in
                XCTFail("Future failed with error - \(error)")
                complete()
            }
        }
    }
    
    func testAsyncResultAlternativeFailure() {
        asyncTest { complete in
            let promise = Promise<String>()
            DispatchQueue.global().async {
                sleep(1)
                try? promise.fulfill(with: "TEST")
            }
            let future = promise.future
            async {
                try future
                    ||>
                    String.lowercased^ >>> { XCTAssert($0 == "test", "Future value not matching: expected-\(Void()), provided-\($0)") }
                    <||>
                    { XCTFail("Future failed with error - \($0)") }
                complete()
                }
                .catch { error in
                    XCTFail("Future failed with error - \(error)")
                    complete()
            }
        }
    }
    
    static var allTests = [
        ("testSyncApplication", testSyncApplication),
        ("testAsyncApplication", testAsyncApplication),
        ("testAsyncResultAlternativeSuccess", testAsyncResultAlternativeSuccess),
        ("testAsyncResultAlternativeFailure", testAsyncResultAlternativeFailure),
        ]
}
