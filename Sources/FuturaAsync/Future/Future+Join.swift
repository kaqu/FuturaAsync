public extension Future {
    
    convenience init<T>(join futures: Future<T>...) where Expectation == Array<T> {
        self.init()
        let count = futures.count
        let lck = Lock()
        var resultsArray: Array<T> = []
        futures.forEach { future in
            future.then { [weak self] value in
                lck.synchronized {
                    resultsArray.append(value)
                    guard resultsArray.count == count else { return }
                    self?.become(resultsArray)
                }
            }
        }
    }
}
