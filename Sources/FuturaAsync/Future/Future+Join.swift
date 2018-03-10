public extension Future {
    
    convenience init<T>(merging futures: Future<T>...) where Value == Array<T> {
        self.init()
        let count = futures.count
        let mtx = Mutex()
        var resultsArray: Array<T> = []
        futures.forEach { future in
            future.result { result in
                mtx.synchronized {
                    switch result {
                    case let .value(val):
                        resultsArray.append(val)
                        guard resultsArray.count == count else { return }
                        try? self.become(with: .value(resultsArray))
                    case let .error(err):
                        try? self.become(with: .error(err))
                    }
                }
            }
        }
    }
}
