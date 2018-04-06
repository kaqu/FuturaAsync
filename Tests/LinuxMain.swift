import XCTest
@testable import FuturaAsyncTests

XCTMain([
    testCase(FuturaAsyncTests.allTests),
    testCase(PromiseAndFutureTests.allTests),
    testCase(WorkerAndCatchableTests.allTests),
    testCase(FutureTests.allTests),
    testCase(LockTests.allTests),
])
