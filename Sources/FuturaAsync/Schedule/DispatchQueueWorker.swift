import Dispatch

public enum DispatchQueueWorker {
    case main
    case `default`
    case utility
    case background
    case custom(DispatchQueue)
}

extension DispatchQueueWorker : Worker {
    
    public func schedule(_ work: @escaping () -> Void) -> Void {
        queue.async(execute: work)
    }
    
    @discardableResult
    public func schedule(_ work: @escaping () throws -> Void) -> Catchable {
        let catchable = Catchable()
        queue.async {
            do {
                try work()
                catchable.close()
            } catch {
                catchable.handle(error: error)
            }
        }
        return catchable
    }
    
    @discardableResult
    public func scheduleAndWait<T>(_ work: @escaping () -> T) -> T {
        return queue.sync(execute: work)
    }
    
    @discardableResult
    public func scheduleAndWait<T>(_ work: @escaping () throws -> T) rethrows -> T {
        return try queue.sync(execute: work)
    }
}

internal extension DispatchQueueWorker {
    
    var queue: DispatchQueue {
        switch self {
        case .main:
            return .main
        case .default:
            return .global(qos: .default)
        case .utility:
            return .global(qos: .utility)
        case .background:
            return .global(qos: .background)
        case let .custom(customQueue):
            return customQueue
        }
    }
}

