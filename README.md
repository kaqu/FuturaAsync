# FuturaAsync

Part of Futura tools Project.

Provides promise implementation for iOS, macOS and Linux.

```
let promise = Promise<String>()
DispatchQueue.global().asyncAfter(deadline: .now()+3) {
try? promise.fulfill(with: "Super!")
}
let future = promise.future

async {
let result = try? future.await()
print(result)
}
print("Async waiting")
```
