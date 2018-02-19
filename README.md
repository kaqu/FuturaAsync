# FuturaAsync

[![Build Status](https://travis-ci.org/kaqu/FuturaAsync.svg?branch=master)](https://travis-ci.org/kaqu/FuturaAsync)
[![codebeat badge](https://codebeat.co/badges/4192d0ed-2655-40c0-9b88-43253d7fb992)](https://codebeat.co/projects/github-com-kaqu-futuraasync-master)
[![codecov](https://codecov.io/gh/kaqu/FuturaAsync/branch/master/graph/badge.svg)](https://codecov.io/gh/kaqu/FuturaAsync)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![SwiftVersion](https://img.shields.io/badge/Swift-4.0-brightgreen.svg)]()
[![Contact](https://img.shields.io/badge/contact-@kaqukal-blue.svg?style=flat)](https://twitter.com/kaqukal)


Part of Futura tools Project.

Provides promise implementation for iOS and macOS.

Use via Swift Package Manager
```swift
.package(url: "https://github.com/kaqu/FuturaAsync.git", from: "0.3.0"),
```

```swift
let promise = Promise<String>() // create promise - way to complete future
DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
    try? promise.fulfill(with: "Works!") // async fulfill
}
let future = promise.future // gather promise future - read only view for async state

async { // async block on default DispatchQueue
    let result = try? future.await() // wait until result or throws error
    print(result)
}
print("Async waiting")
```

You can map futures to other types
```swift
let promise = Promise<Int>()
// Handler called only if value recived, errors passed unmodified
let stringValueFuture: Future<String> = promise.future.valueMap { value in return "\(value)" }
// Handler called on value and on error
let stringResultFuture: Future<String> = promise.future.map { result in 
    switch result {
    case let value(value):
        return "\(value)" 
    case let error(error):
        throw error
    }
}
```

You can try to recover from future fails
```swift
let promise = Promise<Int>()
// Handler called when error occours
let future = promise.future.withRecovery { error throws -> Int in return 0 }
```

You can merge and join multiple futures
```swift
let promise_1 = Promise<Int8>()
let promise_2 = Promise<Int16>()
// merge different types to tuple (up to four)
let mergedFuture: Future<(Int8,Int16)> = Future(merging: promise_1.future, promise_2.future)
// join same type to array (any number)
let joinedFuture: Future<[Void]> = Future(joining: Promise<Void>().future, Promise<Void>().future, Promise<Void>().future)

```

