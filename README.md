# FuturaAsync

Part of Futura tools Project.

Provides promise implementation for iOS, macOS and Linux.

```
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
