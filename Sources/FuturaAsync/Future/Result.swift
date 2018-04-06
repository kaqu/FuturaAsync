public enum Result<Value> {
    case value(Value)
    case error(Error)
}

public extension Result {
    
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
    
    public func mapValue<T>(_ transform: (Value) throws -> T) -> Result<T> {
        switch self {
        case .value(let val): return Result<T> { try transform(val) }
        case .error(let e): return .error(e)
        }
    }
}
