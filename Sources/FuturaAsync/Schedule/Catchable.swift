public final class Catchable {
    
    private let future: FailableFuture<Void> = Future()
    
    public func `catch`(_ handler: @escaping (Error) -> Void) -> Void {
        future.catch(perform: handler)
    }
    
    internal func handle(error: Error) {
        future.fail(with: error)
    }
    
    internal func close() {
        future.succeed(with: Void())
    }
}
