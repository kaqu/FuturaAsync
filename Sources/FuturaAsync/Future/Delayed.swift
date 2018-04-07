public final class Delayed<Value> {
    
    public let future: Future<Value> = Future()
    
    public init() {}
    
    public func become(_ value: Value) {
        future.become(value)
    }
}
