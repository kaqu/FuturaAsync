public enum FutureResult<Value> {
    case value(Value)
    case error(Error)
}

public extension FutureResult {
    
    init(resolving closure: () throws -> Value) {
        do {
            self = .value(try closure())
        } catch {
            self = .error(error)
        }
    }
    
    func unwrap() throws -> Value {
        switch self {
        case let .value(val): return val
        case let .error(err): throw err
        }
    }
    
    public func map<T>(_ transform: (Value) throws -> T) -> FutureResult<T> {
        switch self {
        case .value(let val): return FutureResult<T> { try transform(val) }
        case .error(let e): return .error(e)
        }
    }
    
    func flatMap<T>(_ transform: (Value) -> FutureResult<T>) -> FutureResult<T> {
        switch self {
        case .value(let val): return transform(val)
        case .error(let e): return .error(e)
        }
    }
}

public enum FutureError : Error {
    case alreadyCompleted
    case timeout
}
