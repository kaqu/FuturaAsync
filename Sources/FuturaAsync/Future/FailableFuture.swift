public typealias FailableFuture<T> = Future<Result<T>>

public extension FailableFuture {
    
    func examineValue<T>() throws -> T? where Expectation == Result<T> {
        guard let result = examine() else { return nil }
        return try result.unwrap()
    }
    
    @discardableResult
    func thenValue<T>(in context: ExecutionContext = .async(using: mainWorker), perform block: @escaping (T) -> ()) -> Self  where Expectation == Result<T> {
        let handlerClosure: (Result<T>)->() = {
            switch $0 {
            case let .value(value):
                block(value)
            case .error: break
            }
        }
        return then(use: FailableFuture.Handler(context: context, handler: handlerClosure))
    }
    
    @discardableResult
    func thenError<T>(in context: ExecutionContext = .async(using: mainWorker), perform block: @escaping (Error) -> ()) -> Self where Expectation == Result<T> {
        let handlerClosure: (Result<T>)->() = {
            switch $0 {
            case .value: break
            case let .error(error):
                block(error)
            }
        }
        return then(use: FailableFuture.Handler(context: context, handler: handlerClosure))
    }
    
    func mapValue<T, Transformed>(in context: ExecutionContext = .inherit, _ transformation: @escaping (T) throws -> (Transformed)) -> FailableFuture<Transformed> where Expectation == Result<T> {
        let mapped = FailableFuture<Transformed>()
        then(in: context) { value in
            do {
                try mapped.succeed(with: transformation(value.unwrap()))
            } catch {
                mapped.fail(with: error)
            }
        }
        return mapped
    }
    
    func recover<T>(in context: ExecutionContext = .inherit, _ recovery: @escaping (Error) throws -> (T)) -> FailableFuture<T> where Expectation == Result<T> {
        let recoverable = FailableFuture<T>()
        then(in: context) { value in
            do {
                try recoverable.succeed(with: value.unwrap())
            } catch {
                do {
                    try recoverable.succeed(with: recovery(error))
                } catch {
                    recoverable.fail(with: error)
                }
            }
        }
        return recoverable
    }
}

internal extension FailableFuture {
    
    func succeed<T>(with value: T) where Expectation == Result<T> {
        become(with: Expectation.value(value))
    }
    
    func fail<T>(with error: Error) where Expectation == Result<T> {
        become(with: Expectation.error(error))
    }
}
