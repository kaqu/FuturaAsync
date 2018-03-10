open class FutureRepresentable<Value> {
    public let future: Future<Value> = Future()
    
    open func complete(with result: FutureResult<Value>) throws {
        try future.become(with: result)
    }
}
