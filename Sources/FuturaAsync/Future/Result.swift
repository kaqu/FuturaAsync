public enum Result<Value> {
    case success(Value)
    case failure(Error)
}

public extension Result {
    
    func unwrap() throws -> Value {
        switch self {
        case let .success(val): return val
        case let .failure(err): throw err
        }
    }
}
