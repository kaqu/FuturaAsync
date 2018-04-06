public func schedule(in context: ExecutionContext = .async(using: defaultWorker), toPerform task: @escaping () -> Void) -> Void {
    context.execute(task)
}

@discardableResult
public func schedule(in context: ExecutionContext = .async(using: defaultWorker), toPerform task: @escaping () throws -> Void) -> Catchable {
    return context.execute(task)
}
