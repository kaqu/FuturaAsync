public final class Delayed<Value> {
    
    public let future: Future<Value> = Future()
    
    func become(result: Value) {
        future.become(with: result)
    }
}
