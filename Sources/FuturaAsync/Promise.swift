import Foundation

public final class Promise <Value> {
    
    public let future: Future<Value> = Future()
    
    public init() {}
}

public extension Promise {
    
    var isCompleted: Bool { return future.isCompleted }
    
    func fulfill(with value: Value) throws {
        try future.complete(with: value)
    }
    
    func fail(with error: Error) throws {
        try future.complete(with: error)
    }
}
