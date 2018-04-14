public final class Catchable {
    
    private let future: EitherFuture<Error, Void> = Future()
    
    public func `catch`(_ handler: @escaping (Error) -> Void) -> Void {
        future.thenLeft(handler)
    }
    
    internal func handle(error: Error) {
        future.becomeLeft(with: error)
    }
    
    internal func close() {
        future.becomeRight(with: Void())
    }
    
    deinit { close() }
}
