import XCTest
@testable import FuturaAsync

class FutureTests: XCTestCase {
    
    func testFutureAwaitTimeout() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            do {
                _ = try future.await(withTimeout: 1)
                XCTFail("Future passed without timeout")
            } catch FutureError.timeout {
                // expected
            } catch {
                XCTFail("Promise failed to complete with unexpected error: \(error)")
            }
            complete()
        }
    }
    
    func testFulfilledFutureMake() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>(with: Void())
            switch future.await() {
            case let .value(val):
                XCTAssert(val == Void(), "Future value not matching: expected-\(Void()), provided-\(val)")
            case .error:
                XCTFail()
            }
            complete()
        }
    }
    
    func testFailedFutureMake() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>(with: "Error")
            switch future.await() {
            case .value:
                XCTFail()
            case let .error(err):
                XCTAssert(err as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(err)")
            }
            complete()
        }
    }
    
    func testDelayedFulfillWithAwait() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            DispatchQueue.global().async {
                sleep(1)
                try? future.fulfill(with: ())
            }
            do {
                let value: Void = try future.await().unwrap()
                XCTAssert(value == Void(), "Future value not matching: expected-\(Void()), provided-\(value)")
            } catch {
                XCTFail("Future failed with error - \(error)")
            }
            complete()
        }
    }
    
    func testDelayedFailWithAwait() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            DispatchQueue.global().async {
                sleep(1)
                try? future.fail(with: "Error")
            }
            do {
                _ = try future.await().unwrap()
                XCTFail("Future not failed")
            } catch {
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
            }
            complete()
        }
    }
    
    func testDelayedFulfillWithValueCallback() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            DispatchQueue.global().async {
                sleep(1)
                try? future.fulfill(with: ())
            }
            future.value { value in
                XCTAssert(value == Void(), "Future value not matching: expected-\(Void()), provided-\(value)")
                complete()
            }
        }
    }
    
    func testDelayedFailWithErrorCallback() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            DispatchQueue.global().async {
                sleep(1)
                try? future.fail(with: "Error")
            }
            future.error { error in
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
                complete()
            }
        }
    }
    
    func testDelayedFulfillWithResultCallback() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            DispatchQueue.global().async {
                sleep(1)
                try? future.fulfill(with: ())
            }
            future.result { result in
                if case let .value(value) = result {
                    XCTAssert(value == Void(), "Future value not matching: expected-\(Void()), provided-\(value)")
                } else {
                    XCTFail("Future failed")
                }
                complete()
            }
        }
    }
    
    func testDelayedFailWithResultCallback() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            DispatchQueue.global().async {
                sleep(1)
                try? future.fail(with: "Error")
            }
            future.result { result in
                if case let .error(error) = result {
                    XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
                } else {
                    XCTFail("Future failed")
                }
                complete()
            }
        }
    }
    
    func testInstantFailWithAwait() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            try? future.fail(with: "Error")
            do {
                _ = try future.await().unwrap()
                XCTFail("Future not failed")
            } catch {
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
            }
            complete()
        }
    }
    
    func testInstantFulfillWithValueCallback() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            try? future.fulfill(with: ())
            future.value { value in
                XCTAssert(value == Void(), "Future value not matching: expected-\(Void()), provided-\(value)")
                complete()
            }
        }
    }
    
    func testInstantFailWithErrorCallback() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            try? future.fail(with: "Error")
            future.error { error in
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
                complete()
            }
        }
    }
    
    func testInstantFulfillWithResultCallback() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            try? future.fulfill(with: ())
            future.result { result in
                if case let .value(value) = result {
                    XCTAssert(value == Void(), "Future value not matching: expected-\(Void()), provided-\(value)")
                } else {
                    XCTFail("Future failed")
                }
                complete()
            }
        }
    }
    
    func testInstantFailWithResultCallback() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            try? future.fail(with: "Error")
            future.result { result in
                if case let .error(error) = result {
                    XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
                } else {
                    XCTFail("Future failed")
                }
                complete()
            }
        }
    }
    
    // MARK: map
    
    func testFutureAwaitTimeoutWithMap() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            let mapped = future.map { "" }
            do {
                _ = try mapped.await(withTimeout: 1)
                XCTFail("Future passed without timeout")
            } catch FutureError.timeout {
                // expected
            } catch {
                XCTFail("Promise failed to complete with unexpected error: \(error)")
            }
            complete()
        }
    }
    
    func testFulfilledFutureMakeWithMap() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>(with: Void())
            let mapped = future.map { "" }
            switch mapped.await() {
            case let .value(val):
                XCTAssert(val == "", "Future value not matching: expected-\(""), provided-\(val)")
            case .error:
                XCTFail()
            }
            complete()
        }
    }
    
    func testFailedFutureMakeWithMap() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>(with: "Error")
            let mapped = future.map { "" }
            switch mapped.await() {
            case .value:
                XCTFail()
            case let .error(err):
                XCTAssert(err as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(err)")
            }
            complete()
        }
    }
    
    func testDelayedFulfillWithAwaitWithMap() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            let mapped = future.map { "" }
            DispatchQueue.global().async {
                sleep(1)
                try? future.fulfill(with: ())
            }
            do {
                let value: String = try mapped.await().unwrap()
                XCTAssert(value == "", "Future value not matching: expected-\(""), provided-\(value)")
            } catch {
                XCTFail("Future failed with error - \(error)")
            }
            complete()
        }
    }
    
    func testDelayedFailWithAwaitWithMap() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            let mapped = future.map { "" }
            DispatchQueue.global().async {
                sleep(1)
                try? future.fail(with: "Error")
            }
            do {
                _ = try mapped.await().unwrap()
                XCTFail("Future not failed")
            } catch {
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
            }
            complete()
        }
    }
    
    func testDelayedFulfillWithValueCallbackWithMap() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            let mapped = future.map { "" }
            DispatchQueue.global().async {
                sleep(1)
                try? future.fulfill(with: ())
            }
            mapped.value { value in
                XCTAssert(value == "", "Future value not matching: expected-\(""), provided-\(value)")
                complete()
            }
        }
    }
    
    func testDelayedFailWithErrorCallbackWithMap() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            let mapped = future.map { "" }
            DispatchQueue.global().async {
                sleep(1)
                try? future.fail(with: "Error")
            }
            mapped.error { error in
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
                complete()
            }
        }
    }
    
    func testDelayedFulfillWithResultCallbackWithMap() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            let mapped = future.map { "" }
            DispatchQueue.global().async {
                sleep(1)
                try? future.fulfill(with: ())
            }
            mapped.result { result in
                if case let .value(value) = result {
                    XCTAssert(value == "", "Future value not matching: expected-\(""), provided-\(value)")
                } else {
                    XCTFail("Future failed")
                }
                complete()
            }
        }
    }
    
    func testDelayedFailWithResultCallbackWithMap() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            let mapped = future.map { "" }
            DispatchQueue.global().async {
                sleep(1)
                try? future.fail(with: "Error")
            }
            mapped.result { result in
                if case let .error(error) = result {
                    XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
                } else {
                    XCTFail("Future failed")
                }
                complete()
            }
        }
    }
    
    func testInstantFailWithAwaitWithMap() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            let mapped = future.map { "" }
            try? future.fail(with: "Error")
            do {
                _ = try mapped.await().unwrap()
                XCTFail("Future not failed")
            } catch {
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
            }
            complete()
        }
    }
    
    func testInstantFulfillWithValueCallbackWithMap() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            let mapped = future.map { "" }
            try? future.fulfill(with: ())
            mapped.value { value in
                XCTAssert(value == "", "Future value not matching: expected-\(""), provided-\(value)")
                complete()
            }
        }
    }
    
    func testInstantFailWithErrorCallbackWithMap() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            let mapped = future.map { "" }
            try? future.fail(with: "Error")
            mapped.error { error in
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
                complete()
            }
        }
    }
    
    func testInstantFulfillWithResultCallbackWithMap() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            let mapped = future.map { "" }
            try? future.fulfill(with: ())
            mapped.result { result in
                if case let .value(value) = result {
                    XCTAssert(value == "", "Future value not matching: expected-\(""), provided-\(value)")
                } else {
                    XCTFail("Future failed")
                }
                complete()
            }
        }
    }
    
    func testInstantFailWithResultCallbackWithMap() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Void>()
            let mapped = future.map { "" }
            try? future.fail(with: "Error")
            mapped.result { result in
                if case let .error(error) = result {
                    XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
                } else {
                    XCTFail("Future failed")
                }
                complete()
            }
        }
    }
}
