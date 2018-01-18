import Foundation

@discardableResult
public func async(using worker: AsyncWorker = Worker.`default`, _ task: @escaping () throws ->()) -> Catchable {
    return worker.schedule(task)
}

/// Type that allows to handle async errors
public final class Catchable {
    internal init() {}
    private let lock: NSLock = NSLock()
    private var _handler: ((Error)->())? = nil
    internal var handler: ((Error)->())? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _handler
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _handler = newValue
        }
    }
    
    /// Method for async catching errors, setting handler overrides previous one
    public func `catch`(_ handler: @escaping (Error)->()) { self.handler = handler }
}
