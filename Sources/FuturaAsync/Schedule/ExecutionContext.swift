public enum ExecutionContext {
    case inherit
    case async(using: Worker)
}

internal extension ExecutionContext {
    
    @inline(__always)
    func execute(_ function: @escaping () -> Void) {
        switch self {
        case .inherit:
            function()
        case let .async(worker):
            worker.schedule(function)
        }
    }
    
    @inline(__always)
    func execute(_ function: @escaping () throws -> Void) -> Catchable {
        let catchable = Catchable()
        switch self {
        case .inherit:
            do {
                try function()
            } catch {
                catchable.handle(error: error)
            }
        case let .async(worker):
            worker.schedule(function)
        }
        return catchable
    }
}
