#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

public enum LockError : Error {
    case timeout
}

public protocol LockProtocol {
    func lock() -> Void
    func lock(timeout: UInt8) throws -> Void
    func tryLock() -> Bool
    func unlock() -> Void
    func synchronized<T>(_ closure: () throws -> T) rethrows -> T
}

fileprivate let nSecMsec: __darwin_time_t = 1_000_000
fileprivate let mSecSec: __darwin_time_t = 1_000 * nSecMsec

public final class Lock : LockProtocol {
    public let mtx = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)

    public init() {
        let attr = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)
        guard pthread_mutexattr_init(attr) == 0 else { preconditionFailure() }
        pthread_mutexattr_settype(attr, PTHREAD_MUTEX_NORMAL)
        pthread_mutexattr_setpshared(attr, PTHREAD_PROCESS_PRIVATE)
        guard pthread_mutex_init(mtx, attr) == 0 else { preconditionFailure() }
        pthread_mutexattr_destroy(attr)
        attr.deinitialize(count: 1)
        attr.deallocate()
    }
    
    deinit {
        pthread_mutex_destroy(mtx)
        mtx.deinitialize(count: 1)
        mtx.deallocate()
    }
    
    @inline(__always)
    public func lock() -> Void {
        pthread_mutex_lock(mtx)
    }
    
    public func lock(timeout: UInt8) throws -> Void {
        var timeout = __darwin_time_t(timeout) * mSecSec
        var rem = timespec(tv_sec: 0, tv_nsec: 0)
        var req = timespec(tv_sec: 0, tv_nsec: 0)
        while pthread_mutex_trylock(mtx) != 0 {
            req.tv_nsec = timeout < nSecMsec ? timeout : nSecMsec
            while nanosleep(&req, &rem) == EINTR {
                req.tv_nsec = rem.tv_nsec
            }
            timeout -= (req.tv_nsec - rem.tv_nsec)
            if timeout <= 0 {
                throw LockError.timeout
            } else { continue }
        }
    }
    
    public func tryLock() -> Bool {
        return pthread_mutex_trylock(mtx) == 0
    }
    
    public func unlock() -> Void {
        pthread_mutex_unlock(mtx)
    }
    
    public func synchronized<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }
}
