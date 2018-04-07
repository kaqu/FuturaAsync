public typealias Promise<T> = Delayed<Result<T>>

public extension Promise {
    
    public convenience init<T>(using worker: Worker = asyncWorker, withRetriesCount retryCount: UInt = 0, performing task: @escaping () throws -> (T))  where Value == Result<T> {
        self.init()
        var lastError: Error?
        worker.schedule {
            for _ in 0...retryCount {
                do { return try self.fulfill(with: task()) } catch { lastError = error }
            }
            guard let lastError = lastError else { return }
            self.break(with: lastError)
        }
    }
    
    public func fulfill<T>(with value: T) where Value == Result<T> {
        future.succeed(with: value)
    }
    
    public func `break`<T>(with error: Error = PromiseError.cancelled) where Value == Result<T> {
        future.fail(with: error)
    }
}
