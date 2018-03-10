public final class Future<Value> {
    public typealias Result = FutureResult<Value>
    public typealias Handler = FutureHandler<Value>
    
    private let mutex: Mutex = Mutex()
    private var handlers: [Handler] = []
    private var unsafeResult: Result?
    
    public init() {
        self.unsafeResult = nil
    }
    
    public init(with value: Value) {
        self.unsafeResult = .value(value)
    }
    
    public init(with error: Error) {
        self.unsafeResult = .error(error)
    }
}

public extension Future {
    
    func await() -> Result {
        var awaitedResult: Result!
        let mtx = Mutex()
        switch (mutex.synchronized { return unsafeResult }) {
        case let .some(result):
            awaitedResult = result
        case .none:
            mtx.lock()
            handle(using: Future.Handler { awaitedResult = $0 ; mtx.unlock() })
        }
        mtx.lock()
        return awaitedResult
    }
    
    func await(withTimeout timeout: UInt8) throws -> Result {
        var awaitedResult: Result!
        let mtx = Mutex()
        switch (mutex.synchronized { return unsafeResult }) {
        case let .some(result):
            awaitedResult = result
        case .none:
            mtx.lock()
            handle(using: Future.Handler { awaitedResult = $0 ; mtx.unlock() })
        }
        do {
            try mtx.lock(timeout: timeout)
        } catch MutexError.timeout {
            throw FutureError.timeout
        } catch {
            throw error
        }
        return awaitedResult
    }
    
    /// Async result handler - always triggered when Future completes
    @discardableResult
    func result(using worker: Worker = mainWorker, _ handler: @escaping (Result) -> ()) -> Self {
        return handle(using: FutureHandler<Value>(associatedWorker: worker, handler: handler))
    }
    
    /// Async value handler - triggered only when Future completes with value
    @discardableResult
    func value(using worker: Worker = mainWorker, _ handler:  @escaping (Value) -> ()) -> Self {
        return handle(using: FutureHandler<Value>(associatedWorker: worker) { result in
            switch result {
            case let .value(value):
                handler(value)
            case .error:
                break
            }
        })
    }
    
    /// Async error handler - triggered only when Future completes with error
    @discardableResult
    func error(using worker: Worker = mainWorker, _ handler:  @escaping (Error) -> ()) -> Self {
        return handle(using: FutureHandler<Value>(associatedWorker: worker) { result in
            switch result {
            case .value:
                break
            case let .error(error):
                handler(error)
            }
        })
    }
    
    
    /// Converts result of future with given function using selected worker
    func map<Transformed>(using worker: Worker = asyncWorker, _ transformation: @escaping (Value) throws -> (Transformed)) -> Future<Transformed> {
        let mapped = Future<Transformed>()
        result(using: worker) { result in
            try? mapped.become(with: result.map(transformation))
        }
        return mapped
    }
}

internal extension Future {
    
    @inline(__always)
    func become(with result: Result) throws {
        try mutex.synchronized {
            switch unsafeResult {
            case .some:
                throw FutureError.alreadyCompleted
            case .none:
                unsafeResult = result
                handlers.forEach { $0.trigger(with: result) }
                handlers = []
            }
        }
    }
    
    @inline(__always)
    func fulfill(with value: Value) throws {
        try become(with: .value(value))
    }
    
    @inline(__always)
    func fail(with error: Error) throws {
        try become(with: .error(error))
    }
}

private extension Future {
    
    @inline(__always)
    @discardableResult
    func handle(using handler: Handler) -> Self {
        mutex.synchronized {
            switch unsafeResult {
            case let .some(result):
                handler.trigger(with: result)
            case .none:
                handlers.append(handler)
            }
        }
        return self
    }
}
