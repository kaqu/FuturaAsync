import XCTest
@testable import FuturaAsync

class PromiseAndFutureTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // since tests are performed on main thread change default closure worker to avoid deadlocks
        Worker.applicationDefault = .default
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFulfillStateChanges() {
        asyncTest { complete in
            let promise = Promise<Void>()
            XCTAssert(promise.isCompleted == false, "Promise completed before completing")
            XCTAssert(promise.future.isCompleted == false, "Future completed before completing")
            try? promise.fulfill(with: ())
            XCTAssert(promise.isCompleted == true, "Promise not completed after completing")
            XCTAssert(promise.future.isCompleted == true, "Future not completed after completing")
            do {
                try promise.fulfill(with: ())
                XCTFail("Promise completed twice")
            } catch FutureError.alreadyCompleted {
                // it is expected - do nothing
            } catch {
                XCTFail("Promise failed to complete twice with unexpected error: \(error)")
            }
            do {
                try promise.fail(with: "Error")
                XCTFail("Promise completed twice")
            } catch FutureError.alreadyCompleted {
                // it is expected - do nothing
            } catch {
                XCTFail("Promise failed to complete twice with unexpected error: \(error)")
            }
            complete()
        }
    }
    
    func testFailStateChanges() {
        asyncTest { complete in
            let promise = Promise<Void>()
            XCTAssert(promise.isCompleted == false, "Promise completed before completing")
            XCTAssert(promise.future.isCompleted == false, "Future completed before completing")
            try? promise.fail(with: "Error")
            XCTAssert(promise.isCompleted == true, "Promise not completed after completing")
            XCTAssert(promise.future.isCompleted == true, "Future not completed after completing")
            do {
                try promise.fulfill(with: ())
                XCTFail("Promise completed twice")
            } catch FutureError.alreadyCompleted {
                // it is expected - do nothing
            } catch {
                XCTFail("Promise failed to complete twice with unexpected error: \(error)")
            }
            do {
                try promise.fail(with: "Error")
                XCTFail("Promise completed twice")
            } catch FutureError.alreadyCompleted {
                // it is expected - do nothing
            } catch {
                XCTFail("Promise failed to complete twice with unexpected error: \(error)")
            }
            complete()
        }
    }
    
    func testFutureTimeout() {
        asyncTest(iterationTimeout: 2) { complete in
            let promise = Promise<Void>()
            do {
                _ = try promise.future.await(withTimeout: 1)
                XCTFail("Future passed without timeout")
            } catch FutureError.timeout {
                // it is expected - do nothing
            } catch {
                XCTFail("Promise failed to complete twice with unexpected error: \(error)")
            }
            complete()
        }
    }
    
    func testFulfilledFutureMake() {
        asyncTest { complete in
            let future = Future<Void>(value: Void())
            XCTAssert(future.isCompleted == true, "Future not completed")
            do {
                let value: Void = try future.await()
                XCTAssert(value == Void(), "Future value not matching: expected-\(Void()), provided-\(value)")
            } catch {
                XCTFail("Future failed")
            }
            complete()
        }
    }
    
    func testFailedFutureMake() {
        asyncTest { complete in
            let future = Future<Void>(error: "Error")
            XCTAssert(future.isCompleted == true, "Future not completed")
            do {
                _ = try future.await()
                XCTFail("Future not failed")
            } catch {
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
            }
            complete()
        }
    }
    
    func testFulfillFutureWithClosureTask() {
        asyncTest { complete in
            let future = Future<Void>() { fulfill, _ in
                try! fulfill(Void())
            }
            do {
                let value: Void = try future.await()
                XCTAssert(value == Void(), "Future value not matching: expected-\(Void()), provided-\(value)")
            } catch {
                XCTFail("Future failed")
            }
            complete()
        }
    }
    
    func testFailFutureWithClosureTask() {
        asyncTest { complete in
            let future = Future<Void>() { _, fail in
                try! fail("Error")
            }
            do {
                _ = try future.await()
                XCTFail("Future not failed")
            } catch {
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
            }
            complete()
        }
    }
    
    func testDelayedFulfillWithAwait() {
        asyncTest { complete in
            let promise = Promise<Void>()
            DispatchQueue.global().async {
                try? promise.fulfill(with: ())
            }
            let future = promise.future
            do {
                let value: Void = try future.await()
                XCTAssert(value == Void(), "Future value not matching: expected-\(Void()), provided-\(value)")
            } catch {
                XCTFail("Future failed")
            }
            complete()
        }
    }
    
    func testDelayedFailWithAwait() {
        asyncTest { complete in
            let promise = Promise<Void>()
            DispatchQueue.global().async {
                try? promise.fail(with: "Error")
            }
            let future = promise.future
            do {
                _ = try future.await()
                XCTFail("Future not failed")
            } catch {
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
            }
            complete()
        }
    }

    func testDelayedFulfillWithValueCallback() {
        asyncTest { complete in
            let promise = Promise<Void>()
            DispatchQueue.global().async {
                try? promise.fulfill(with: ())
            }
            promise.future.value { value in
                XCTAssert(value == Void(), "Future value not matching: expected-\(Void()), provided-\(value)")
                complete()
            }
        }
    }
    
    func testDelayedFailWithErrorCallback() {
        asyncTest { complete in
            let promise = Promise<Void>()
            DispatchQueue.global().async {
                try? promise.fail(with: "Error")
            }
            promise.future.error { error in
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
                complete()
            }
        }
    }
    
    func testDelayedFulfillWithResultCallback() {
        asyncTest { complete in
            let promise = Promise<Void>()
            DispatchQueue.global().async {
                try? promise.fulfill(with: ())
            }
            promise.future.result { result in
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
        asyncTest { complete in
            let promise = Promise<Void>()
            DispatchQueue.global().async {
                try? promise.fail(with: "Error")
            }
            promise.future.result { result in
                if case let .error(error) = result {
                    XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
                } else {
                    XCTFail("Future failed")
                }
                complete()
            }
        }
    }
    
    func testInstantFulfillWithAwait() {
        asyncTest { complete in
            let promise = Promise<Void>()
            try? promise.fulfill(with: ())
            let future = promise.future
            do {
                let value: Void = try future.await()
                XCTAssert(value == Void(), "Future value not matching: expected-\(Void()), provided-\(value)")
            } catch {
                XCTFail("Future failed")
            }
            complete()
        }
    }
    
    func testInstantFailWithAwait() {
        asyncTest { complete in
            let promise = Promise<Void>()
            try? promise.fail(with: "Error")
            let future = promise.future
            do {
                _ = try future.await()
                XCTFail("Future not failed")
            } catch {
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
            }
            complete()
        }
    }
    
    func testInstantFulfillWithValueCallback() {
        asyncTest { complete in
            let promise = Promise<Void>()
            try? promise.fulfill(with: ())
            promise.future.value { value in
                XCTAssert(value == Void(), "Future value not matching: expected-\(Void()), provided-\(value)")
                complete()
            }
        }
    }
    
    func testInstantFailWithErrorCallback() {
        asyncTest { complete in
            let promise = Promise<Void>()
            try? promise.fail(with: "Error")
            promise.future.error { error in
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
                complete()
            }
        }
    }
    
    func testInstantFulfillWithResultCallback() {
        asyncTest { complete in
            let promise = Promise<Void>()
            try? promise.fulfill(with: ())
            promise.future.result { result in
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
        asyncTest { complete in
            let promise = Promise<Void>()
            try? promise.fail(with: "Error")
            promise.future.result { result in
                if case let .error(error) = result {
                    XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
                } else {
                    XCTFail("Future failed")
                }
                complete()
            }
        }
    }
    
    func testDelayedFulfillWithAwaitUsingMap() {
        asyncTest { complete in
            let promise = Promise<Void>()
            DispatchQueue.global().async {
                try? promise.fulfill(with: ())
            }
            let future = promise.future.map { _ in return (0 as Int) }
            do {
                let value: Int = try future.await()
                XCTAssert(value == 0, "Future value not matching: expected-\(0), provided-\(value)")
            } catch {
                XCTFail("Future failed")
            }
            complete()
        }
    }
    
    func testDelayedFailWithAwaitUsingMap() {
        asyncTest { complete in
            let promise = Promise<Void>()
            DispatchQueue.global().async {
                try? promise.fail(with: "Error")
            }
            let future = promise.future.map { _ in return (0 as Int) }
            do {
                _ = try future.await()
                XCTFail("Future not failed")
            } catch {
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
            }
            complete()
        }
    }
    
    func testDelayedFulfillWithValueCallbackUsingMap() {
        asyncTest { complete in
            let promise = Promise<Void>()
            DispatchQueue.global().async {
                try? promise.fulfill(with: ())
            }
            promise.future.map { _ in return (0 as Int) }.value { value in
                XCTAssert(value == 0, "Future value not matching: expected-\(0), provided-\(value)")
                complete()
            }
        }
    }
    
    func testDelayedFailWithErrorCallbackUsingMap() {
        asyncTest { complete in
            let promise = Promise<Void>()
            DispatchQueue.global().async {
                try? promise.fail(with: "Error")
            }
            promise.future.map { _ in return (0 as Int) }.error { error in
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
                complete()
            }
        }
    }
    
    func testDelayedFulfillWithResultCallbackUsingMap() {
        asyncTest { complete in
            let promise = Promise<Void>()
            DispatchQueue.global().async {
                try? promise.fulfill(with: ())
            }
            promise.future.map { _ in return (0 as Int) }.result { result in
                if case let .value(value) = result {
                    XCTAssert(value == 0, "Future value not matching: expected-\(0), provided-\(value)")
                } else {
                    XCTFail("Future failed")
                }
                complete()
            }
        }
    }
    
    func testDelayedFailWithResultCallbackUsingMap() {
        asyncTest { complete in
            let promise = Promise<Void>()
            DispatchQueue.global().async {
                try? promise.fail(with: "Error")
            }
            promise.future.map { _ in return (0 as Int) }.result { result in
                if case let .error(error) = result {
                    XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
                } else {
                    XCTFail("Future failed")
                }
                complete()
            }
        }
    }
    
    func testInstantFulfillWithAwaitUsingMap() {
        asyncTest { complete in
            let promise = Promise<Void>()
            try? promise.fulfill(with: ())
            let future = promise.future.map { _ in return (0 as Int) }
            do {
                let value: Int = try future.await()
                XCTAssert(value == 0, "Future value not matching: expected-\(0), provided-\(value)")
            } catch {
                XCTFail("Future failed")
            }
            complete()
        }
    }
    
    func testInstantFailWithAwaitUsingMap() {
        asyncTest { complete in
            let promise = Promise<Void>()
            try? promise.fail(with: "Error")
            let future = promise.future.map { _ in return (0 as Int) }
            do {
                _ = try future.await()
                XCTFail("Future not failed")
            } catch {
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
            }
            complete()
        }
    }
    
    func testInstantFulfillWithValueCallbackUsingMap() {
        asyncTest { complete in
            let promise = Promise<Void>()
            try? promise.fulfill(with: ())
            promise.future.map { _ in return (0 as Int) }.value { value in
                XCTAssert(value == 0, "Future value not matching: expected-\(0), provided-\(value)")
                complete()
            }
        }
    }
    
    func testInstantFailWithErrorCallbackUsingMap() {
        asyncTest { complete in
            let promise = Promise<Void>()
            try? promise.fail(with: "Error")
            promise.future.map { _ in return (0 as Int) }.error { error in
                XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
                complete()
            }
        }
    }
    
    func testInstantFulfillWithResultCallbackUsingMap() {
        asyncTest { complete in
            let promise = Promise<Void>()
            try? promise.fulfill(with: ())
            promise.future.map { _ in return (0 as Int) }.result { result in
                if case let .value(value) = result {
                    XCTAssert(value == 0, "Future value not matching: expected-\(0), provided-\(value)")
                } else {
                    XCTFail("Future failed")
                }
                complete()
            }
        }
    }
    
    func testInstantFailWithResultCallbackUsingMap() {
        asyncTest { complete in
            let promise = Promise<Void>()
            try? promise.fail(with: "Error")
            promise.future.map { _ in return (0 as Int) }.result { result in
                if case let .error(error) = result {
                    XCTAssert(error as? String == "Error", "Future error not matching: expected-\("Error"), provided-\(error)")
                } else {
                    XCTFail("Future failed")
                }
                complete()
            }
        }
    }
    
    static var allTests = [
        ("testFulfillStateChanges", testFulfillStateChanges),
        ("testFailStateChanges", testFailStateChanges),
        ("testFutureTimeout", testFutureTimeout),
        ("testFailedFutureMake", testFailedFutureMake),
        ("testFulfillFutureWithClosureTask", testFulfillFutureWithClosureTask),
        ("testFailFutureWithClosureTask", testFailFutureWithClosureTask),
        ("testDelayedFulfillWithAwait", testDelayedFulfillWithAwait),
        ("testDelayedFailWithAwait", testDelayedFailWithAwait),
        ("testDelayedFulfillWithValueCallback", testDelayedFulfillWithValueCallback),
        ("testDelayedFailWithErrorCallback", testDelayedFailWithErrorCallback),
        ("testDelayedFulfillWithResultCallback", testDelayedFulfillWithResultCallback),
        ("testDelayedFailWithResultCallback", testDelayedFailWithResultCallback),
        ("testInstantFulfillWithAwait", testInstantFulfillWithAwait),
        ("testInstantFailWithAwait", testInstantFailWithAwait),
        ("testInstantFulfillWithValueCallback", testInstantFulfillWithValueCallback),
        ("testInstantFailWithErrorCallback", testInstantFailWithErrorCallback),
        ("testInstantFulfillWithResultCallback", testInstantFulfillWithResultCallback),
        ("testInstantFailWithResultCallback", testInstantFailWithResultCallback),
        ("testDelayedFulfillWithAwaitUsingMap", testDelayedFulfillWithAwaitUsingMap),
        ("testDelayedFailWithAwaitUsingMap", testDelayedFailWithAwaitUsingMap),
        ("testDelayedFulfillWithValueCallbackUsingMap", testDelayedFulfillWithValueCallbackUsingMap),
        ("testDelayedFailWithErrorCallbackUsingMap", testDelayedFailWithErrorCallbackUsingMap),
        ("testDelayedFulfillWithResultCallbackUsingMap", testDelayedFulfillWithResultCallbackUsingMap),
        ("testDelayedFailWithResultCallbackUsingMap", testDelayedFailWithResultCallbackUsingMap),
        ("testInstantFulfillWithAwaitUsingMap", testInstantFulfillWithAwaitUsingMap),
        ("testInstantFailWithAwaitUsingMap", testInstantFailWithAwaitUsingMap),
        ("testInstantFulfillWithValueCallbackUsingMap", testInstantFulfillWithValueCallbackUsingMap),
        ("testInstantFailWithErrorCallbackUsingMap", testInstantFailWithErrorCallbackUsingMap),
        ("testInstantFulfillWithResultCallbackUsingMap", testInstantFulfillWithResultCallbackUsingMap),
        ("testInstantFailWithResultCallbackUsingMap", testInstantFailWithResultCallbackUsingMap),
        ]
}
