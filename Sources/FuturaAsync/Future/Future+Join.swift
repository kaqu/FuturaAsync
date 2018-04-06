public extension Future {
    
    convenience init<T>(merging futures: Future<T>...) where Expectation == Array<T> {
        self.init()
        let count = futures.count
        let lck = Lock()
        var resultsArray: Array<T> = []
        futures.forEach { future in
            future.then { value in
                lck.synchronized {
                    resultsArray.append(value)
                    guard resultsArray.count == count else { return }
                }
            }
        }
    }
}
