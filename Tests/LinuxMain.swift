import XCTest
@testable import FuturaAsyncTests

XCTMain([
    testCase(FuturaAsyncTests.allTests),
    testCase(PromiseAndFutureTests.allTests),
    testCase(WorkerTests.allTests),
])
