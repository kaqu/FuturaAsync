import Foundation

/**
 Promise is declaration of delayed/async value. Use it to manipulate result of that declaration.
 */
public final class Promise<Value> : FutureRepresentable<Value> {

    /**
     Promise with task closure and retry count (default is 0) that will be performed using given worker to complete
     */
    public convenience init(using worker: Worker = asyncWorker, withTriesCount retryCount: UInt = 0, performing task: @escaping () throws -> (Value)) {
        self.init()
        worker.schedule {
            var lastError: Error!
            for _ in 0...retryCount {
                do { return try self.fulfill(with:task()) } catch { lastError = error }
            }
            try? self.reject(with:lastError)
        }
    }
}

public extension Promise {

    // MARK: control

    /**
     Fulfill promise - completes successfully with value.
     Throws an error if Future was already completed.
     */
    func fulfill(with value: Value) throws {
        try future.fulfill(with: value)
    }

    /**
     Fail promise with error - completes unsuccessfully with error.
     Throws an error if Future was already completed.
     */
    func reject(with error: Error) throws {
        try future.fail(with: error)
    }
}

