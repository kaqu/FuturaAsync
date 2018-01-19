import Foundation

@discardableResult
public func async(using worker: AsyncWorker = Worker.`default`, _ task: @escaping () throws ->()) -> Catchable {
    return worker.schedule(task)
}

/// Type that allows to handle async errors,
public final class Catchable {
    internal init() { self.selfReference = self }
    private let lock: NSLock = NSLock()
    private var selfReference: Catchable? = nil
    private var completed: Bool = false
    private var error: Error? = nil
    private var handlers: [(Error)->()] = []
    
    /// Method for async catching all errors, handler will be released after error occourance
    public func `catch`(_ handler: @escaping (Error)->()) {
        lock.lock()
        defer { lock.unlock() }
        if let error = error {
            handler(error)
        } else if !completed {
            self.handlers.append(handler)
        } else { return }
    }
    
    /// Method to complete and cleanup (may be used to complete with or without error)
    internal func complete(with error: Error?) {
        lock.lock()
        defer { lock.unlock() ; selfReference = nil }
        guard !completed else {
            return
        }
        if let error = error {
            self.error = error
            handlers.forEach { $0(error) }
        } else { /* nothing */ }
        
        handlers = []
        completed = true
    }
}
