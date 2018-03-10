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
                catchable.complete()
            } catch {
                catchable.complete(with: error)
            }
        }
        return catchable
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

