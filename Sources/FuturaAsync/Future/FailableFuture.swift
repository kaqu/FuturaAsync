public typealias FailableFuture<T> = Future<Result<T>>

public extension FailableFuture {
    
    func examineValue<T>() throws -> T? where Expectation == Result<T> {
        guard let result = examine() else { return nil }
        return try result.unwrap()
    }
    
    @discardableResult
    func thenSuccess<T>(in context: ExecutionContext = .async(using: defaultWorker), perform block: @escaping (T) -> ()) -> Self  where Expectation == Result<T> {
        let handlerClosure: (Result<T>)->() = {
            switch $0 {
            case let .success(value):
                block(value)
            case .failure: break
            }
        }
        return then(use: FailableFuture.Handler(context: context, handler: handlerClosure))
    }
    
    @discardableResult
    func thenFailure<T>(in context: ExecutionContext = .async(using: defaultWorker), perform block: @escaping (Error) -> ()) -> Self where Expectation == Result<T> {
        let handlerClosure: (Result<T>)->() = {
            switch $0 {
            case .success: break
            case let .failure(error):
                block(error)
            }
        }
        return then(use: FailableFuture.Handler(context: context, handler: handlerClosure))
    }
    
    func mapValue<T, Transformed>(to: Transformed.Type, in context: ExecutionContext = .inherit, _ transformation: @escaping (T) throws -> (Transformed)) -> FailableFuture<Transformed> where Expectation == Result<T> {
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
    
    func recoverable<T>(in context: ExecutionContext = .inherit, using recovery: @escaping (Error) throws -> (T)) -> FailableFuture<T> where Expectation == Result<T> {
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
        become(Expectation.success(value))
    }
    
    func fail<T>(with error: Error) where Expectation == Result<T> {
        become(Expectation.failure(error))
    }
}
