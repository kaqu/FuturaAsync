import Foundation

public final class FutureReceptacle<Value> {
    private var value: Value?
    private let lock: NSConditionLock
    private var waiters: [Waiter] = []
    
    public init() {
        self.value = nil
        self.lock = NSConditionLock(condition: futureCondition)
    }
    
    public init(with value: Value) {
        self.value = value
        self.lock = NSConditionLock(condition: nowCondition)
    }
    
    public func examine(in handler: (State<Value>) -> ()) {
        self.lock.lock()
        defer { self.lock.unlock() }
        guard let result = self.value else {
            handler(.inFuture)
            return
        }
        handler(.now(result))
    }
    
    internal func becameNow(with value: Value) throws -> Void {
        guard self.lock.tryLock(whenCondition: futureCondition) else {
            throw FutureReceptacleError.alreadyCompleted
        }
        defer { self.lock.unlock(withCondition: nowCondition) }
        self.value = value
        waiters.forEach { waiter in waiter.worker.schedule { waiter.task(value) } }
        waiters = []
    }
    
    public func waitFor(withTimeout timeout: TimeInterval? = nil) throws -> Value {
        if let timeout = timeout {
            guard lock.lock(whenCondition: nowCondition, before: Date(timeIntervalSinceNow: timeout)) else {
                throw FutureReceptacleError.timeout
            }
        } else {
            lock.lock(whenCondition: nowCondition)
        }
        defer { lock.unlock() }
        return value!
    }
    
    public func withWaiter(waiter: Waiter) -> Self {
        examine {
            switch $0 {
            case .inFuture:
                waiters.append(waiter)
            case let .now(result):
                waiter.worker.schedule { waiter.task(result) }
            }
        }
        return self
    }
    
    public func map<Transformed>(using worker: Worker = asyncWorker, _ transformation: @escaping (Value) throws -> (Transformed)) -> FutureReceptacle<Transformed> {
        let mapped = FutureReceptacle<Transformed>()
        waiters.append((worker: worker, task: {
            try? mapped.becameNow(with: transformation($0))
        }))
        return mapped
    }
}

public extension FutureReceptacle {
    typealias Waiter = (worker: Worker, task: (Value) -> Void)
}

fileprivate let futureCondition: Int = 0
fileprivate let nowCondition: Int = 1

public extension FutureReceptacle {
    public indirect enum State<Value> {
        case inFuture
        case now(Value)
    }
}

public enum FutureReceptacleError : Swift.Error {
    case timeout
    case alreadyCompleted
}

