public final class Delayed<Value> {
    
    public let future: Future<Value> = Future()
    
    func become(_ value: Value) {
        future.become(value)
    }
}
