import Foundation

/// AsyncSpace
public final class AsyncSpace<Property> {
    
    private let lock: NSConditionLock = NSConditionLock(condition: AsyncSpaceLock.present)
 
    // TODO: add buffer if no portals recieving
    private var portals: [Portal<Property>] = []
    
    internal func broadcast(property: Property, from portal: Portal<Property>) throws {
        defer { lock.unlock() }
        guard !lock.tryLock(whenCondition: AsyncSpaceLock.vanished) else { throw AsyncSpaceError.vanished }
        lock.lock()
        portals.filter { $0 !== portal} .forEach {  try? $0.assignBufferValue(property) }
    }
    
    internal func open(portal: Portal<Property>) throws {
        guard !lock.tryLock(whenCondition: AsyncSpaceLock.vanished) else {
            lock.unlock()
            throw AsyncSpaceError.vanished
        }
        defer { lock.unlock() }
        lock.lock()
        
        guard nil == portals.index(where: { $0 === portal }) else { return } // already open so.. do nothing
        portals.append(portal)
    }
    
    internal func close(portal: Portal<Property>) {
        defer { lock.unlock() }
        guard !lock.tryLock(whenCondition: AsyncSpaceLock.vanished) else { return }
        lock.lock()
        
        guard let index = portals.index(where: { $0 === portal }) else { return }
        portals.remove(at: index)
    }
    
    /// Close space and all pointing portals
    public func close() {
        self.portals.forEach { $0.close() }
        defer { self.lock.unlock(withCondition: AsyncSpaceLock.vanished) }
        self.lock.lock()
        self.portals = []
    }
    
    /// Makes new Portal pointing to this space
    public func spawnPortal() throws -> Portal<Property> {
        return try Portal<Property>(with: self)
    }
    
    deinit { close() }
}

public enum AsyncSpaceError : Error { case vanished }

fileprivate enum AsyncSpaceLock {
    fileprivate static let present = 1
    fileprivate static let vanished = -1
}
