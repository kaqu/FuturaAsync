public func schedule(in context: ExecutionContext = .async(using: asyncWorker), toPerform task: @escaping () -> Void) -> Void {
    context.execute(task)
}

@discardableResult
public func schedule(in context: ExecutionContext = .async(using: asyncWorker), toPerform task: @escaping () throws -> Void) -> Catchable {
    return context.execute(task)
}
