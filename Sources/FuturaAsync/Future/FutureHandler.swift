public final class FutureHandler<Value> {
    
    internal let context: ExecutionContext
    internal let handler: (Value) -> Void
    
    public init(context: ExecutionContext = .inherit, handler: @escaping (Value) -> Void) {
        self.context = context
        self.handler = handler
    }
}

internal extension FutureHandler {
    
    func trigger(with value: Value) -> Void {
        context.execute {
            self.handler(value)
        }
    }
}
