import Foundation

public func schedule(using worker: Worker = asyncWorker, toPerform task: @escaping () -> Void) -> Void {
    worker.schedule(task)
}

@discardableResult
public func schedule(using worker: Worker = asyncWorker, toPerform task: @escaping () throws -> Void) -> Catchable {
    return worker.schedule(task)
}
