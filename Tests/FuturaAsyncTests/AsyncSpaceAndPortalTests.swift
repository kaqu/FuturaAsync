import XCTest
@testable import FuturaAsync

class PortalTests: XCTestCase {
    
    func testAsyncSpaceClosing() {
        asyncTest { complete in
            do {
                let space = AsyncSpace<String>()
                let portal = try space.spawnPortal()

                let testPayload = "payload1"
                try portal.send(payload: testPayload)
                try portal.closeAssociatedSpace()
                space.close(portal: portal)
                do {
                    _ = try space.broadcast(property: "", from: portal)
                    XCTFail("Expected to throw")
                } catch { /* expected */ }
                do {
                    _ = try space.open(portal: portal)
                    XCTFail("Expected to throw")
                } catch { /* expected */ }
                do {
                    try portal.send(payload: testPayload)
                    XCTFail("Expected to throw")
                } catch { /* expected */ }
                do {
                    _ = try portal.recieve()
                    XCTFail("Expected to throw")
                } catch { /* expected */ }
                do {
                    try portal.closeAssociatedSpace()
                } catch { /* expected */ }
                do {
                    try portal.send(payload: testPayload)
                    XCTFail("Expected to throw")
                } catch { /* expected */ }
                do {
                    _ = try portal.recieve()
                    XCTFail("Expected to throw")
                } catch { /* expected */ }
                complete()
            } catch {
                XCTFail("Unexpected error: \(error)")
                complete()
            }
        }
    }
    func testPortalBuffer() {
        asyncTest { complete in
            do {
                let portal1 = try AsyncSpace<String>().spawnPortal()
                let portal2 = try portal1.clone()
                
                let payload1 = "payload1"
                try portal1.send(payload: payload1)
                let payload2 = "payload2"
                try portal1.send(payload: payload2)
                let payload3 = "payload3"
                try portal1.send(payload: payload3)
                try? portal1.closeAssociatedSpace()
                var count = 0
                while let payload = try? portal2.recieve() {
                    switch count {
                    case 0:
                        XCTAssert(payload == payload1, "Payload not matching expected (\(payload) vs \(payload1))")
                    case 1:
                        XCTAssert(payload == payload2, "Payload not matching expected (\(payload) vs \(payload2))")
                    case 2:
                        XCTAssert(payload == payload3, "Payload not matching expected (\(payload) vs \(payload3))")
                    default:
                        XCTFail("Extra payload - not excepted: \(payload)")
                    }
                    count += 1
                }
                XCTAssert(count == 3, "Recived incorrect number of payloads - \(count)")
                complete()
            } catch {
                XCTFail("Unexpected error: \(error)")
                complete()
            }
        }
    }
    
    func testPortalBroadcast() {
        asyncTest { complete in
            do {
                let portal1 = try AsyncSpace<String>().spawnPortal()
                
                let payload1 = "payload1"
                let payload2 = "payload2"
                let payload3 = "payload3"
                (0..<10).forEach { iteration in
                    async {
                        let portal = try portal1.clone()
                        var count = 0
                        while let payload = try? portal.recieve() {
                            switch count {
                            case 0:
                                XCTAssert(payload == payload1, "Payload not matching expected (\(payload) vs \(payload1)) in iteration \(iteration)")
                            case 1:
                                XCTAssert(payload == payload2, "Payload not matching expected (\(payload) vs \(payload2)) in iteration \(iteration)")
                            case 2:
                                XCTAssert(payload == payload3, "Payload not matching expected (\(payload) vs \(payload3)) in iteration \(iteration)")
                            default:
                                XCTFail("Extra payload - not excepted: \(payload)")
                            }
                            count += 1
                        }
                        portal.close()
                    }
                }
                try portal1.send(payload: payload1)
                try portal1.send(payload: payload2)
                try portal1.send(payload: payload3)
                portal1.close()
                complete()
            } catch {
                XCTFail("Unexpected error: \(error)")
                complete()
            }
        }
    }

    static var allTests = [
        ("testAsyncSpaceClosing", testAsyncSpaceClosing),
        ("testPortalBuffer", testPortalBuffer),
        ("testPortalBroadcast", testPortalBroadcast),
        ]
}
