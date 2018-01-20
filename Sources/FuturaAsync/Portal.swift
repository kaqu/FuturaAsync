import Foundation

/// Access to AsyncSpace
public final class Portal<Payload> {
    
    private var space: AsyncSpace<Payload>?
    private let lock: NSConditionLock = NSConditionLock(condition: PortalLock.waiting)
    
    private var payloadBuffer: [Payload] = []
    private func bufferValue() throws -> Payload {
        let unlockCondition: Int
        defer { lock.unlock(withCondition: unlockCondition) }
        lock.lock(whenCondition: PortalLock.ready)
        unlockCondition = (payloadBuffer.count > 1 || space == nil) ? PortalLock.ready : PortalLock.waiting
        guard let payload = payloadBuffer.popLast() else { throw PortalError.portalClosed }
        return payload
    }
    internal func assignBufferValue(_ payload: Payload) throws {
        defer { lock.unlock(withCondition: PortalLock.ready) }
        lock.lock()
        guard nil != space else { throw PortalError.portalClosed }
        payloadBuffer.insert(payload, at: 0)
    }

    internal init(with dimension: AsyncSpace<Payload>) throws {
        self.space = dimension
        try dimension.open(portal: self)
    }
    
    /// Broadcasts payload through associated space
    public func send(payload: Payload) throws {
        defer { lock.unlock() }
        lock.lock()
        guard let dimension = space else { throw PortalError.portalClosed }
        try dimension.broadcast(property: payload, from: self)
    }
    
    /// Recive value emmited via regisered space, blocks thread!
    public func recieve() throws -> Payload {
        return try bufferValue()
    }
    
    /// Close portal Closed Portal cannot recieve or distribute payloads, except payloads in buffer
    public func close() {
        defer { lock.unlock(withCondition: PortalLock.ready) } // unlock in ready to unlock all waiting threads
        lock.lock()
        guard let dimension = space else { return } // already closed
        self.space = nil
        dimension.close(portal: self)
    }
    
    /// Close associated space with all pointing portals
    public func closeAssociatedSpace() throws {
        guard let dimension = space else { throw PortalError.portalClosed }
        dimension.close()
    }
    
    /// Duplicates portal pointing to same space
    public func clone() throws -> Portal {
        defer { lock.unlock() }
        lock.lock()
        guard let dimension = space else { throw PortalError.portalClosed }
        return try Portal(with: dimension)
    }
    
    deinit { close() }
}

public enum PortalError : Error { case portalClosed }

fileprivate enum PortalLock {
    fileprivate static let waiting = 0
    fileprivate static let ready = 1
}
