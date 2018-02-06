# FuturaAsync

[![Build Status](https://travis-ci.org/kaqu/FuturaAsync.svg?branch=master)](https://travis-ci.org/kaqu/FuturaAsync)

Part of Futura tools Project.

Provides promise implementation for iOS, macOS and Linux.

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

