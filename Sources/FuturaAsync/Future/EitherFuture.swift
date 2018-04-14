import FuturaFunc

public typealias EitherFuture<T, U> = Future<Either<T, U>>

public extension EitherFuture {
    
    @discardableResult
    func thenLeft<T, U>(in context: ExecutionContext = .inherit, _ handler: @escaping (T) -> ()) -> Self where Value == Either<T, U> {
        return then { (value: Value) -> Void in
            switch value {
            case let .left(lval):
                handler(lval)
            case .right: break
            }
        }
    }
    
    func thenLeft<T, U>(in context: ExecutionContext = .inherit, _ handler: @escaping (T) -> (T)) -> Future<T> where Value == Either<T, U> {
        let next = Future<T>()
        then { (value: Value) -> Void in
            switch value {
            case let .left(lval):
                next.become(handler(lval))
            case .right: break
            }
        }
        return next
    }
    
    func mapLeft<T, U, W>(to: W.Type, in context: ExecutionContext = .inherit, _ handler: @escaping (T) -> (W)) -> Future<Either<W, U>> where Value == Either<T, U> {
        let next = Future<Either<W, U>>()
        then { (value: Value) -> Void in
            switch value {
            case let .left(lval):
                next.becomeLeft(with: handler(lval))
            case let .right(rval):
                next.becomeRight(with: rval)
            }
        }
        return next
    }
    
    @discardableResult
    func thenRight<T, U>(in context: ExecutionContext = .inherit, _ handler: @escaping (U) -> ()) -> Self where Value == Either<T, U> {
        return then { (value: Value) -> Void in
            switch value {
            case .left: break
            case let .right(rval):
                handler(rval)
            }
        }
    }
    
    func thenRight<T, U>(in context: ExecutionContext = .inherit, _ handler: @escaping (U) -> (U)) -> Future<U> where Value == Either<T, U> {
        let next = Future<U>()
        then { (value: Value) -> Void in
            switch value {
            case .left: break
            case let .right(rval):
                next.become(handler(rval))
            }
        }
        return next
    }
    
    func mapRight<T, U, W>(to: W.Type, in context: ExecutionContext = .inherit, _ handler: @escaping (U) -> (W)) -> Future<Either<T, W>> where Value == Either<T, U> {
        let next = Future<Either<T, W>>()
        then { (value: Value) -> Void in
            switch value {
            case let .left(lval):
                next.becomeLeft(with: lval)
            case let .right(rval):
                next.becomeRight(with: handler(rval))
            }
        }
        return next
    }
}

internal extension EitherFuture {
    
    func becomeLeft<T, U>(with value: T) where Value == Either<T, U> {
        become(Value.left(value))
    }
    
    func becomeRight<T, U>(with value: U) where Value == Either<T, U> {
        become(Value.right(value))
    }
}
