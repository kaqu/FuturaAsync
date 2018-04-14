public final class Future<Value> {
    public typealias Handler = (Value) -> Void
    
    private let lock: Lock = Lock()
    private let executionContext: ExecutionContext
    private var handlers: [Handler] = []
    private var value: Value?

    public init(with value: Value? = nil, executionContext: ExecutionContext = .async(using: defaultWorker)) {
        self.executionContext = executionContext
        self.value = value
    }
    
    deinit {
        #if DEBUG
        guard case .none = expectation else { return }
        print("WARNING - dealocating not completed future! - \(self)")
        #endif
    }
}

public extension Future {
    
    @discardableResult
    func then(_ handler: @escaping (Value) -> ()) -> Self {
        lock.synchronized {
            switch value {
            case let .some(result):
                executionContext.execute { handler(result) }
            case .none:
                handlers.append(handler)
            }
        }
        return self
    }
    
    func then( _ handler: @escaping (Value) -> (Value)) -> Future<Value> {
        let next = Future<Value>()
        then { value in
            next.become(handler(value))
        }
        return next
    }
    
    func map<Transformed>(to: Transformed.Type, _ transformation: @escaping (Value) -> (Transformed)) -> Future<Transformed> {
        let mapped = Future<Transformed>()
        then { value in
            mapped.become(transformation(value))
        }
        return mapped
    }
    
    @discardableResult
    func after(_ handler: @escaping () -> ()) -> Self {
        return then { _ in handler() }
    }
    
    func using(context: ExecutionContext) -> Future<Value> {
        let fut = Future(executionContext: context)
        then { fut.become($0) }
        return fut
    }
    
    @discardableResult
    func keep() -> Self {
        return after { _ = self }
    }
}

internal extension Future {
    
    func become(_ value: Value) {
        lock.synchronized {
            switch self.value {
            case .some:
                return
            case .none:
                self.value = value
                executionContext.execute {
                    self.handlers.forEach { $0(value) }
                    self.handlers = []
                }
                
            }
        }
    }
}

public func future<T>(using worker: Worker, _ task: @escaping () -> T) -> Future<T> {
    let future = Future<T>()
    worker.schedule {
        future.become(task())
    }
    return future
}
