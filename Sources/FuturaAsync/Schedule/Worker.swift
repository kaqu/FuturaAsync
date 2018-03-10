/// worker using main thread/queue of application
public var mainWorker: Worker = DispatchQueueWorker.main
/// default async worker
public var asyncWorker: Worker = DispatchQueueWorker.default

public protocol Worker {
    
    func schedule(_ work: @escaping () -> Void) -> Void
    
    @discardableResult
    func schedule(_ work: @escaping () throws -> Void) -> Catchable
}
