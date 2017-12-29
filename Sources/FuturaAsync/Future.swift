//
//  Future.swift
//  FuturaCore
//
//  Created by Kacper Kaliński on 01/12/2017.
//  Copyright © 2017 kaqu. All rights reserved.
//

import Foundation

/// Errors that can be produced by future itself
public enum FutureError : Swift.Error {
    case timeout
    case incomplete
    case alreadyCompleted
    case recoveryFailedWith(Error)
}

/// Internal lock value
internal enum FutureLockConst : Int {
    case waiting = -1
    case completed = 0
}

/// Read only object representing async value
public final class Future<Value> {
    
    private var resultHandlers: Array<(AsyncWorker, (Result)->())> = []
    private var valueHandlers: Array<(AsyncWorker, (Value)->())> = []
    private var errorHandlers: Array<(AsyncWorker, (Error)->())> = []
    private var recoveryHandler: ((Error)throws->(Value))?
    
    fileprivate let lock: NSConditionLock
    private var state: State { didSet { complete() } }
    fileprivate var synchronizedState: State {
        get {
            lock.lock()
            defer { self.lock.unlock() }
            return state
        }
    }
    
    /// Make new Future waiting for value or error
    internal init() {
        state = .waiting
        lock = NSConditionLock(condition: FutureLockConst.waiting.rawValue)
    }
    
    /// Make new, completed Future object with given value
    public init(value: Value) {
        state = .ready(value)
        lock = NSConditionLock(condition: FutureLockConst.completed.rawValue)
    }
    
    /// Make new, completed Future object with given error
    public init(error: Error) {
        state = .error(error)
        lock = NSConditionLock(condition: FutureLockConst.completed.rawValue)
    }
    
    /// Make new Future object with task closure that will be performed using given worker to complete
    public init(using worker: AsyncWorker = Worker.default, with task: @escaping ((Value) throws ->() , (Error) throws ->())->()) {
        state = .waiting
        lock = NSConditionLock(condition: FutureLockConst.waiting.rawValue)
        worker.do {
            task({ (val: Value) in
                try self.complete(with: val)
            }, { (err: Error) in
                try self.complete(with: err)
            })
        }
    }
}

public extension Future {
    
    /// State of Future
    var isCompleted: Bool {
        return synchronizedState.isCompleted
    }
}

extension Future {
    
    /// Possible states of Future
    public indirect enum State {
        case waiting
        case ready(Value)
        case error(Error)
    }
}

internal extension Future.State {
    
    var isCompleted: Bool {
        switch self {
        case .waiting:
            return false
        case .ready, .error:
            return true
        }
    }
}

extension Future {
    
    /// Possible results of Future
    public indirect enum Result {
        case value(Value)
        case error(Error)
    }
}

fileprivate extension Future.State {
    
    // Internal func for getting result of Future
    func result() throws -> Future.Result {
        switch self {
        case .waiting: throw FutureError.incomplete
        case let .ready(value): return .value(value)
        case let .error(reason): return .error(reason)
        }
    }
}

internal extension Future {
    
    /// Future completion with given value - Future can be completed only once
    func complete(with value: Value) throws {
        lock.lock()
        defer { self.lock.unlock(withCondition: FutureLockConst.completed.rawValue) }
        guard !state.isCompleted else {
            throw FutureError.alreadyCompleted
        }
        state = .ready(value)
    }
    
    /// Future completion with given error - Future can be completed only once. If Recovery handler is set, it will trigger it trying to recover from error
    func complete(with error: Error) throws {
        lock.lock()
        defer { self.lock.unlock(withCondition: FutureLockConst.completed.rawValue) }
        guard !state.isCompleted else {
            throw FutureError.alreadyCompleted
        }
        if let recoveryHandler = recoveryHandler {
            do {
                try state = .ready(recoveryHandler(error))
            } catch {
                state = .error(error)
            }
        } else {
            state = .error(error)
        }
    }
}

public extension Future {
    
    /// Thread blocking, synchronous way of getting Future value. Can take timeout value (in seconds) or wait forever if no timeout provided
    func await(withTimeout timeout: TimeInterval? = nil) throws -> Value {
        if let timeout = timeout {
            guard lock.lock(whenCondition: FutureLockConst.completed.rawValue, before: Date(timeIntervalSinceNow: timeout)) else {
                throw FutureError.timeout
            }
        } else {
            lock.lock(whenCondition: FutureLockConst.completed.rawValue)
        }
        defer { lock.unlock() }
        switch try state.result() {
        case let .value(value):
            return value
        case let .error(error):
            throw error
        }
    }
}

public extension Future {
    
    /// Async result handler - always triggered when Future completes
    @discardableResult
    func result(using worker: AsyncWorker = Worker.applicationDefault, _ handler: @escaping (Result)->()) -> Self {
        lock.lock()
        defer { self.lock.unlock() }
        do {
            let result = try state.result()
            worker.do { handler(result) }
        } catch {
            resultHandlers.append((worker, handler))
        }
        return self
    }
    
    /// Async value handler - triggered only when Future completes with value
    @discardableResult
    func value(using worker: AsyncWorker = Worker.applicationDefault, _ handler:  @escaping (Value)->()) -> Self {
        lock.lock()
        defer { self.lock.unlock() }
        do {
            if case let .value(value) = try state.result() { worker.do { handler(value) } }
        } catch {
            valueHandlers.append((worker, handler))
        }
        return self
    }
    
    /// Async error handler - triggered only when Future completes with error
    @discardableResult
    func error(using worker: AsyncWorker = Worker.applicationDefault, _ handler:  @escaping (Error)->()) -> Self {
        lock.lock()
        defer { self.lock.unlock() }
        do {
            if case let .error(error) = try state.result() { worker.do { handler(error) } }
        } catch {
            errorHandlers.append((worker, handler))
        }
        return self
    }
    
    
    /// Converts result of future with given function using selected worker
    func map<Transformed>(using worker: AsyncWorker = Worker.default, _ transformation: @escaping (Result)throws->(Transformed)) -> Future<Transformed> {
        let mapped = Future<Transformed>()
        result(using: worker) {
            do {
                try mapped.complete(with: transformation($0))
            } catch {
                try? mapped.complete(with: error)
            }
        }
        return mapped
    }
    
    /// Converts value of future with given function using selected worker, if source Future fails error is passed without modification, skipping transformation
    func valueMap<Transformed>(using worker: AsyncWorker = Worker.default, _ transformation: @escaping (Value)throws->(Transformed)) -> Future<Transformed> {
        let mapped = Future<Transformed>()
        result(using: worker) {
            do {
                switch $0 {
                case let .value(value):
                    try mapped.complete(with: transformation(value))
                case let .error(error):
                    try mapped.complete(with: error)
                }
            } catch {
                try? mapped.complete(with: error)
            }
        }
        return mapped
    }
    
    /// Sets recovery function trigerred when Future recives error as completion, overrides previous value if any. After triggerring or completing with value, function is released. Recovery handler is called on same thread which triggered completion with error, it should not be blocking or take long time to complete. If Future is already completed it takes no effect
    func withRecovery(using worker: AsyncWorker = Worker.default, _ handler: @escaping (Error)throws->(Value)) -> Future {
        lock.lock()
        defer { self.lock.unlock() }
        guard !state.isCompleted else {
            return self
        }
        recoveryHandler = handler
        return self
    }
}

fileprivate extension Future {
    
    func complete() { // must be synced
        let result = try! state.result() // must be completed here
        switch result {
        case let .value(value):
            valueHandlers.forEach { worker, handler in worker.do { handler(value) } }
        case let .error(error):
            errorHandlers.forEach { worker, handler in worker.do { handler(error) } }
        }
        resultHandlers.forEach { worker, handler in worker.do { handler(result) } }
        
        // release memory - prevents retain cycles
        resultHandlers = []
        valueHandlers = []
        errorHandlers = []
        recoveryHandler = nil
    }
}
