public final class Future<Expectation> {
    public typealias Handler = FutureHandler<Expectation>
    
    private let lock: Lock = Lock()
    private var handlers: [Handler] = []
    private var expectation: Expectation?
    
    public init() {
        self.expectation = nil
    }
    
    public init(with expectation: Expectation) {
        self.expectation = expectation
    }
}

public extension Future {
    
    func examine() -> Expectation? {
        return lock.synchronized { expectation }
    }
    
    @discardableResult
    func after(in context: ExecutionContext = .async(using: defaultWorker), perform block: @escaping () -> ()) -> Self {
        return then(use: Future.Handler(context: context, handler: { _ in block() }))
    }
    
    @discardableResult
    func then(in context: ExecutionContext = .async(using: defaultWorker), perform block: @escaping (Expectation) -> ()) -> Self {
        return then(use: Future.Handler(context: context, handler: block))
    }
    
    @discardableResult
    func then(use handler: Handler) -> Self {
        lock.synchronized {
            switch expectation {
            case let .some(result):
                handler.trigger(with: result)
            case .none:
                handlers.append(handler)
            }
        }
        return self
    }
    
    func map<Transformed>(to: Transformed.Type, in context: ExecutionContext = .inherit, _ transformation: @escaping (Expectation) throws -> (Transformed)) -> Future<Transformed> {
        let mapped = Future<Transformed>()
        then(in: context) { value in
            try? mapped.become(transformation(value))
        }
        return mapped
    }
}

internal extension Future {
    
    func become(_ value: Expectation) {
        lock.synchronized {
            switch expectation {
            case .some:
                return
            case .none:
                expectation = value
                handlers.forEach { $0.trigger(with: value) }
                handlers = []
            }
        }
    }
}
