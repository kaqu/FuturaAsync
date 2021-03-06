# FuturaAsync

[![Build Status](https://travis-ci.org/kaqu/FuturaAsync.svg?branch=master)](https://travis-ci.org/kaqu/FuturaAsync)
[![Platforms](https://img.shields.io/badge/platform-iOS%20|%20macOS%20|%20Linux-gray.svg?style=flat)]()
[![codebeat badge](https://codebeat.co/badges/4192d0ed-2655-40c0-9b88-43253d7fb992)](https://codebeat.co/projects/github-com-kaqu-futuraasync-master)
[![codecov](https://codecov.io/gh/kaqu/FuturaAsync/branch/master/graph/badge.svg)](https://codecov.io/gh/kaqu/FuturaAsync)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![SwiftVersion](https://img.shields.io/badge/Swift-4.1-brightgreen.svg)]()
[![Contact](https://img.shields.io/badge/contact-@kaqukal-blue.svg?style=flat)](https://twitter.com/kaqukal)


Part of Futura tools Project.

Provides promise implementation for iOS, macOS and Linux.

Use via Swift Package Manager

``` swift
.package(url: "https://github.com/kaqu/FuturaAsync.git", from: "0.9.0"),
```

Sample usage

```swift
let promise = Promise<Int>()
let future = promise.future
future
    .thenSuccess {
        print("Success: \($0)")
    }
    .thenFailure {
        print("Error: \($0)")
    }
    .mapValue {
        return String($0)
    }
    .thenSuccess {
        print("Success(mapped): \($0)")
    }
    .thenFailure {
        print("Error(mapped): \($0)")
    }
    .recoverable { err in
        if (err as? String) == "recoverable" {
            return "Recovery!"
        } else {
            throw err
        }
    }
    .thenSuccess {
        print("Success(mapped, recoverable): \($0)")
    }
    .thenFailure {
        print("Error(mapped, recoverable): \($0)")
    }
    .map {
        switch $0 {
        case let .value(val):
            return val
        case .error:
            return "Errors sometimes happen"
        }
    }
    .then { (val: String) in
        print("Always success(mapped, recoverable, map to Future form FailableFuture): \(val)")
    }
```

calling

``` swift
promise.fulfill(with: 9)
```

prints

```
Success: 9
Success(mapped): 9
Success(mapped, recoverable): 9
Always success(mapped, recoverable, map to Future form FailableFuture): 9
```

calling

``` swift
promise.break() // cancel
```

prints

```
Error: cancelled
Error(mapped): cancelled
Error(mapped, recoverable): cancelled
Always success(mapped, recoverable, map to Future form FailableFuture): Errors sometimes happen
```

calling

``` swift
promise.break(with: "recoverable" as Error)
```

prints

```
Error: recoverable
Error(mapped): recoverable
Success(mapped, recoverable): Recovery!
Always success(mapped, recoverable, map to Future form FailableFuture): Recovery!
```
