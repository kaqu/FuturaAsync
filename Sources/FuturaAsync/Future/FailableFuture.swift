import FuturaFunc

public typealias FailableFuture<T> = Future<Either<T, Error>>

public extension FailableFuture {

    func recoverable<T>(in context: ExecutionContext = .inherit, using recovery: @escaping (Error) throws -> (T)) -> FailableFuture<T> where Value == Either<T, Error> {
        let recoverable = FailableFuture<T>()
        then { (value: Value) -> Void in
            switch value {
            case let .left(lval):
                recoverable.becomeLeft(with: lval)
            case let .right(rval):
                do {
                    try recoverable.becomeLeft(with: recovery(rval))
                } catch {
                    recoverable.becomeRight(with: rval)
                }
            }
        }
        return recoverable
    }
}
