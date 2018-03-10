import Foundation

///// Type that allows to handle async errors,
//public final class Catchable {
//    private let mtx: Mutex = Mutex()
//    private var completed: Bool = false
//    private var error: Error? = nil
//    private var handlers: [(Error) -> ()] = []
//
//    /// Method for async catching all errors, handler will be released after error occourance
//    public func `catch`(_ handler: @escaping (Error) -> Void) -> Void {
//        mtx.lock()
//        defer { mtx.unlock() }
//        if let error = error {
//            handler(error)
//        } else if !completed {
//            self.handlers.append(handler)
//        } else { return }
//    }
//
//    /// Method to complete and cleanup (may be used to complete with or without error)
//    internal func complete(with error: Error? = nil) -> Void {
//        mtx.lock()
//        defer { mtx.unlock() }
//        guard !completed else {
//            return
//        }
//        if let error = error {
//            self.error = error
//            handlers.forEach { $0(error) }
//        } else { /* nothing */ }
//
//        handlers = []
//        completed = true
//    }
//}

public final class Catchable : FutureRepresentable<Void> {
    
    public func `catch`(_ handler: @escaping (Error) -> Void) -> Void {
        future.error(handler)
    }
    
    internal func complete(with error: Error? = nil) -> Void {
        switch error {
        case let .some(err):
            try? complete(with: .error(err))
        case .none:
            try? complete(with: .value(Void()))
        }
        
    }
}
