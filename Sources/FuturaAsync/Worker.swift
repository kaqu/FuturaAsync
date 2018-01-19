import Foundation

public protocol AsyncWorker {
    
    @discardableResult
    func schedule(_ work: @escaping () throws ->()) -> Catchable
    
    @discardableResult
    func schedule(after: TimeInterval, _ work: @escaping () throws ->()) -> Catchable
}

public enum Worker {
    
    public static var applicationDefault: Worker = .main
    
    case main
    case `default`
    case utility
    case background
    case custom(DispatchQueue)
}

extension Worker : AsyncWorker {
    
    @discardableResult
    public func schedule(_ work: @escaping () throws ->()) -> Catchable {
        let catchable = Catchable()
        queue.async {
            do {
                try work()
                catchable.complete(with: nil)
            } catch {
                catchable.complete(with: error)
            }
        }
        return catchable
    }
    
    @discardableResult
    public func schedule(after: TimeInterval, _ work: @escaping () throws ->()) -> Catchable {
        let catchable = Catchable()
        queue.asyncAfter(deadline: .now() + after) {
            do {
                try work()
                catchable.complete(with: nil)
            } catch {
                catchable.complete(with: error)
            }
        }
        return catchable
    }
}

internal extension Worker {
    
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
