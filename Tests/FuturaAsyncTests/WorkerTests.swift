import XCTest
@testable import FuturaAsync

class WorkerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Worker.applicationDefault = .main
    }
    
    func testWokrerQueues() {
        XCTAssert(Worker.applicationDefault.queue == .main, "Application default worker is not main queue")
        XCTAssert(Worker.main.queue == .main, "Main worker is not main queue")
        XCTAssert(Worker.default.queue == .global(qos: .default), "Default worker is not default queue")
        XCTAssert(Worker.utility.queue == .global(qos: .utility), "Utility worker is not utility queue")
        XCTAssert(Worker.background.queue == .global(qos: .background), "Background worker is not background queue")
        let testQueue = DispatchQueue(label: "TestQueue")
        XCTAssert(Worker.custom(testQueue).queue == testQueue, "Custom worker is not custom queue")
    }
    
    func testWorkerClosurePerform() {
        asyncTest { complete in
            Worker.default.schedule {
                complete()
            }
        }
    }

    static var allTests = [
        ("testWokrerQueues", testWokrerQueues),
        ("testWorkerClosurePerform", testWorkerClosurePerform),
        ]
}
