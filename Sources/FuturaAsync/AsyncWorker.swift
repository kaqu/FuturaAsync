//
//  AsyncWorker.swift
//  FuturaCore
//
//  Created by Kacper Kaliński on 30/11/2017.
//  Copyright © 2017 kaqu. All rights reserved.
//

import Foundation

public protocol Work {
    func `do`()
}

public protocol AsyncWorker {
    func `do`(_ work: @escaping ()->())
}

public extension AsyncWorker {
    func `do`(_ work: Work) { self.do(work.do) }
}

public func async(using worker: AsyncWorker = Worker.`default`, _ task: @escaping ()->()) {
    worker.do(task)
}

public enum Worker {
    
    public static var applicationDefault: Worker = .main
    
    case main
    case `default`
    case utility
    case background
    case custom(DispatchQueue)
}

extension Worker : AsyncWorker {
    
    public func `do`(_ work: @escaping ()->()) {
        queue.async {
            work()
        }
    }
}

internal extension Worker {
    
    var queue: DispatchQueue {
        switch self {
        case .main:
            return .main
        case .default:
            return .global(qos: .default)
        case .utility:
            return .global(qos: .utility)
        case .background:
            return .global(qos: .background)
        case let .custom(customQueue):
            return customQueue
        }
    }
}
