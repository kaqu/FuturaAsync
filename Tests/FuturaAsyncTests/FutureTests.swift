import XCTest
@testable import FuturaAsync

class FutureTests: XCTestCase {
    
    func testSuccessFutureChain() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let promise = Promise<Int>()
            let future = promise.future
            promise.fulfill(with: 1)
            future
                .thenSuccess {
                    XCTAssert($0 == 1, "Value not matching expected - \($0) != 1")
                }
                .thenFailure {
                    XCTFail("Unexpected error \($0)")
                }
                .mapValue(to: String.self) {
                    return String($0)
                }
                .thenSuccess {
                    XCTAssert($0 == "1", "Value not matching expected - \($0) != 1")
                }
                .thenFailure {
                    XCTFail("Unexpected error \($0)")
                }
                .recoverable { err in
                    if (err as? String) == "recoverable" {
                        return "rec"
                    } else {
                        throw err
                    }
                }
                .thenSuccess {
                    XCTAssert($0 == "1", "Value not matching expected - \($0) != 1")
                }
                .thenFailure {
                    XCTFail("Unexpected error \($0)")
                }
                .map(to: String.self) {
                    switch $0 {
                    case let .success(val):
                        return val
                    case .failure:
                        return "ign"
                    }
                }
                .then { (val: String) in
                    XCTAssert(val == "1", "Value not matching expected - \(val) != 1")
                    
                }
                .after { complete() }
            }
    }
    
    func testRecoverableFutureChain() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let promise = Promise<Int>()
            let future = promise.future
            promise.break(with: "recoverable")
            future
                .thenSuccess { _ in
                    XCTFail("Expected to fail")
                }
                .thenFailure {
                    XCTAssert($0 as? String == "recoverable", "Error not matching expected - \($0) != recoverable")
                }
                .mapValue(to: String.self) {
                    return String($0)
                }
                .thenSuccess { _ in
                    XCTFail("Expected to fail")
                }
                .thenFailure {
                    XCTAssert($0 as? String == "recoverable", "Error not matching expected - \($0) != recoverable")
                }
                .recoverable { err in
                    if (err as? String) == "recoverable" {
                        return "rec"
                    } else {
                        throw err
                    }
                }
                .thenSuccess {
                    XCTAssert($0 == "rec", "Value not matching expected - \($0) != rec")
                }
                .thenFailure {
                    XCTFail("Unexpected error \($0)")
                }
                .map(to: String.self) {
                    switch $0 {
                    case let .success(val):
                        return val
                    case .failure:
                        return "ign"
                    }
                }
                .then { (val: String) in
                    XCTAssert(val == "rec", "Value not matching expected - \(val) != rec")
                    
                }
                .after { complete() }
        }
    }
    
    func testErrorFutureChain() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let promise = Promise<Int>()
            let future = promise.future
            promise.break(with: "ERR")
            future
                .thenSuccess { _ in
                    XCTFail("Expected to fail")
                }
                .thenFailure {
                    XCTAssert($0 as? String == "ERR", "Error not matching expected - \($0) != ERR")
                }
                .mapValue(to: String.self) {
                    return String($0)
                }
                .thenSuccess { _ in
                    XCTFail("Expected to fail")
                }
                .thenFailure {
                    XCTAssert($0 as? String == "ERR", "Error not matching expected - \($0) != ERR")
                }
                .recoverable { err in
                    if (err as? String) == "recoverable" {
                        return "rec"
                    } else {
                        throw err
                    }
                }
                .thenSuccess { _ in
                    XCTFail("Expected to fail")
                }
                .thenFailure {
                    XCTAssert($0 as? String == "ERR", "Error not matching expected - \($0) != ERR")
                }
                .map(to: String.self) {
                    switch $0 {
                    case let .success(val):
                        return val
                    case .failure:
                        return "ign"
                    }
                }
                .then { (val: String) in
                    XCTAssert(val == "ign", "Value not matching expected - \(val) != ign")
                    
                }
                .after { complete() }
        }
    }
    
    func testFutureWithInitialValue() {
        let future = FailableFuture<Int>(with: .success(1))
        if let val = try? future.examineValue() {
            XCTAssert(val == 1, "Value not matching expected - \(String(describing: val)) != 1")
        } else {
            XCTFail("Expected to contain value")
        }
    }
    
    func testDelayedValue() {
        let delayed = Delayed<Int>()
        let future = delayed.future
        delayed.become(1)
        XCTAssert(future.examine() == 1, "Value not matching expected - \(String(describing: future.examine())) != 1")
    }
    
    func testFutureJoin() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let delayed_1 = Delayed<Int>()
            let delayed_2 = Delayed<Int>()
            let delayed_3 = Delayed<Int>()
            delayed_1.become(1)
            delayed_2.become(2)
            delayed_3.become(3)
            let future = Future(join: delayed_1.future, delayed_2.future, delayed_3.future)
            future.then {
                XCTAssert($0.contains(1) && $0.contains(2) && $0.contains(3), "Value not matching expected - \($0) != [1, 2, 3]")
                future.after { complete() }
            }
        }
    }
    
    func testPromiseWithRetrySuccess() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            var counter = 0
            let promise = Promise<Int>(withRetriesCount: 3) {
                if counter > 2 {
                    return 1
                } else {
                    counter += 1
                    throw "ERR"
                }
            }
            let future = promise.future
            
            future.then {
                XCTAssert((try? $0.unwrap()) == 1, "Value not matching expected - \($0) != 1")
            }
            .after { complete() }
            
        }
    }
    
    func testPromiseWithRetryFailure() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            var counter = 0
            let promise = Promise<Int>(withRetriesCount: 0) {
                if counter > 2 {
                    return 1
                } else {
                    counter += 1
                    throw "ERR"
                }
            }
            let future = promise.future
            
            future.then {
                do {
                    _ = try $0.unwrap()
                    XCTFail("Expected to fail")
                } catch {
                    XCTAssert((error as? String) == "ERR", "Error not matching expected - \($0) != ERR")
                }
            }
            .after { complete() }
            
        }
    }
        
    static var allTests = [
        ("testSuccessFutureChain", testSuccessFutureChain),
        ("testRecoverableFutureChain", testRecoverableFutureChain),
        ("testErrorFutureChain", testErrorFutureChain),
        ("testFutureWithInitialValue", testFutureWithInitialValue),
        ("testDelayedValue", testDelayedValue),
        ("testFutureJoin", testFutureJoin),
        ("testPromiseWithRetrySuccess", testPromiseWithRetrySuccess),
        ("testPromiseWithRetryFailure", testPromiseWithRetryFailure),
    ]
}
