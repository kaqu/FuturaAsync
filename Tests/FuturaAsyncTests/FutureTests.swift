import XCTest
import FuturaFunc
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
                .thenLeft {
                    XCTAssert($0 == 1, "Value not matching expected - \($0) != 1")
                }
                .thenRight {
                    XCTFail("Unexpected error \($0)")
                }
                .mapLeft(to: String.self) {
                    return String($0)
                }
                .thenLeft {
                    XCTAssert($0 == "1", "Value not matching expected - \($0) != 1")
                }
                .thenRight {
                    XCTFail("Unexpected error \($0)")
                }
                .recoverable { err in
                    if (err as? String) == "recoverable" {
                        return "rec"
                    } else {
                        throw err
                    }
                }
                .thenLeft {
                    XCTAssert($0 == "1", "Value not matching expected - \($0) != 1")
                }
                .thenRight {
                    XCTFail("Unexpected error \($0)")
                }
                .map(to: String.self) {
                    switch $0 {
                    case let .left(val):
                        return val
                    case .right:
                        return "ign"
                    }
                }
                .then {
                    XCTAssert($0 == "1", "Value not matching expected - \($0) != 1")
                    
                }
                .after(complete)
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
                .thenLeft { _ in
                    XCTFail("Expected to fail")
                }
                .thenRight {
                    XCTAssert($0 as? String == "recoverable", "Error not matching expected - \($0) != recoverable")
                }
                .mapLeft(to: String.self) {
                    return String($0)
                }
                .thenLeft { _ in
                    XCTFail("Expected to fail")
                }
                .thenRight {
                    XCTAssert($0 as? String == "recoverable", "Error not matching expected - \($0) != recoverable")
                }
                .recoverable { err in
                    if (err as? String) == "recoverable" {
                        return "rec"
                    } else {
                        throw err
                    }
                }
                .thenLeft {
                    XCTAssert($0 == "rec", "Value not matching expected - \($0) != rec")
                }
                .thenRight {
                    XCTFail("Unexpected error \($0)")
                }
                .map(to: String.self) {
                    switch $0 {
                    case let .left(val):
                        return val
                    case .right:
                        return "ign"
                    }
                }
                .then {
                    XCTAssert($0 == "rec", "Value not matching expected - \($0) != rec")
                    
                }
                .after(complete)
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
                .thenLeft { _ in
                    XCTFail("Expected to fail")
                }
                .thenRight {
                    XCTAssert($0 as? String == "ERR", "Error not matching expected - \($0) != ERR")
                }
                .mapLeft(to: String.self) {
                    return String($0)
                }
                .thenLeft { _ in
                    XCTFail("Expected to fail")
                }
                .thenRight {
                    XCTAssert($0 as? String == "ERR", "Error not matching expected - \($0) != ERR")
                }
                .recoverable { err in
                    if (err as? String) == "recoverable" {
                        return "rec"
                    } else {
                        throw err
                    }
                }
                .thenLeft { _ in
                    XCTFail("Expected to fail")
                }
                .thenRight {
                    XCTAssert($0 as? String == "ERR", "Error not matching expected - \($0) != ERR")
                }
                .map(to: String.self) {
                    switch $0 {
                    case let .left(val):
                        return val
                    case .right:
                        return "ign"
                    }
                }
                .then {
                    XCTAssert($0 == "ign", "Value not matching expected - \($0) != ign")
                }
                .after(complete)
        }
    }
    
    func testFutureWithInitialValue() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let future = Future<Int>(with: 1)
            future.then {
                XCTAssert($0 == 1, "Value not matching expected - \($0) != 1")
            }
            .after(complete)
        }
    }
    
    func testDelayedValue() {
        asyncTest(timeoutBody: {
            XCTFail("Not in time - possible deadlock or fail")
        })
        { complete in
            let delayed = Delayed<Int>()
            let future = delayed.future
            delayed.become(1)
            future.then {
                XCTAssert($0 == 1, "Value not matching expected - \($0) != 1")
            }
            .after(complete)
        }
    }
    
    func testFutureJoin() {
// TODO: complete join - some error in implementation
//        asyncTest(timeoutBody: {
//            XCTFail("Not in time - possible deadlock or fail")
//        })
//        { complete in
//            let delayed_1 = Delayed<Int>()
//            let delayed_2 = Delayed<Int>()
//            let delayed_3 = Delayed<Int>()
//            delayed_1.become(1)
//            delayed_2.become(2)
//            delayed_3.become(3)
//            let future = Future(join: delayed_1.future, delayed_2.future, delayed_3.future)
//            future.then {
//                XCTAssert($0.contains(1) && $0.contains(2) && $0.contains(3), "Value not matching expected - \($0) != [1, 2, 3]")
//            }
//            .after(complete)
//        }
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
            future.then { (value: Either<Int, Error>) -> Void in
                switch value {
                case let .left(val):
                    XCTAssert(val == 1, "Value not matching expected - \(val) != 1")
                case .right:
                    XCTFail("Expected left")
                }
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
            
            future.then { (value: Either<Int, Error>) -> Void in
                switch value {
                case .left:
                    XCTFail("Expected to fail")
                case let .right(err):
                    XCTAssert((err as? String) == "ERR", "Error not matching expected - \(err) != ERR")
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
