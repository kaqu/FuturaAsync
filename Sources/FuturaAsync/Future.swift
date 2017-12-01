//
//  Future.swift
//  FuturaCore
//
//  Created by Kacper Kaliński on 01/12/2017.
//  Copyright © 2017 kaqu. All rights reserved.
//

import Foundation

public enum FutureError : Swift.Error {
    case timeout
    case incomplete
    case alreadyCompleted
}

internal enum FutureLockConst : Int {
    case waiting = -1
    case completed = 0
}

public final class Future<Value> {
    
    private var resultHandlers: Array<(AsyncWorker, (Result)->())> = []
    private var valueHandlers: Array<(AsyncWorker, (Value)->())> = []
    private var errorHandlers: Array<(AsyncWorker, (Error)->())> = []
    
    fileprivate let lock: NSConditionLock
    private var state: State { didSet { complete() } }
    fileprivate var synchronizedState: State {
        get {
            lock.lock()
            defer { self.lock.unlock() }
            return state
        }
    }
    
    public init(value: Value? = nil) {
        if let value = value {
            state = .ready(value)
            lock = NSConditionLock(condition: FutureLockConst.completed.rawValue)
        } else {
            state = .waiting
            lock = NSConditionLock(condition: FutureLockConst.waiting.rawValue)
        }
    }
    
    public init(error: Error) {
        state = .error(error)
        lock = NSConditionLock(condition: FutureLockConst.completed.rawValue)
    }
    
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
    
    var isCompleted: Bool {
        return synchronizedState.isCompleted
    }
}

extension Future {
    
    public indirect enum State {
        case waiting
        case ready(Value)
        case error(Error)
    }
}

extension Future.State {
    
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
    
    public indirect enum Result {
        case value(Value)
        case error(Error)
    }
}

fileprivate extension Future.State {
    
    func result() throws -> Future.Result {
        switch self {
        case .waiting: throw FutureError.incomplete
        case let .ready(value): return .value(value)
        case let .error(reason): return .error(reason)
        }
    }
}

internal extension Future {
    
    func complete(with value: Value) throws {
        lock.lock()
        defer { self.lock.unlock(withCondition: FutureLockConst.completed.rawValue) }
        guard !state.isCompleted else {
            throw FutureError.alreadyCompleted
        }
        state = .ready(value)
    }
    
    func complete(with error: Error) throws {
        lock.lock()
        defer { self.lock.unlock(withCondition: FutureLockConst.completed.rawValue) }
        guard !state.isCompleted else {
            throw FutureError.alreadyCompleted
        }
        state = .error(error)
    }
}

public extension Future {
    
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
    
    func map<Transformed>(using worker: AsyncWorker = Worker.default, _ transformation: @escaping (Value)->(Transformed)) -> Future<Transformed> {
        let mapped = Future<Transformed>()
        result(using: worker) {
            switch $0 {
            case let .value(value):
                try? mapped.complete(with: transformation(value))
            case let .error(error):
                try? mapped.complete(with: error)
            }
        }
        return mapped
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
    }
}
