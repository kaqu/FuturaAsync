public final class FutureHandler<Value> {
    
    internal let associatedWorker: Worker?
    internal let handler: (FutureResult<Value>) -> Void
    
    public init(associatedWorker: Worker? = nil, handler: @escaping (FutureResult<Value>) -> Void) {
        self.associatedWorker = associatedWorker
        self.handler = handler
    }
}

internal extension FutureHandler {
    
    func trigger(with result: FutureResult<Value>) -> Void {
        switch associatedWorker {
        case let .some(worker):
            worker.schedule { self.handler(result) }
        case .none:
            self.handler(result)
        }
    }
}
