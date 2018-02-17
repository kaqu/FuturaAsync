import FuturaFunc

precedencegroup AsyncForwardApplicationPrecedence {
    higherThan: ForwardApplicationPrecedence
    lowerThan: ForwardCompositionPrecedence
    associativity: left
}

infix operator ||> : AsyncForwardApplicationPrecedence

public func ||><A, B>(a: Future<A>, f: (A)->(B)) throws -> B {
    return try f(a.await())
}

public func ||><A, B>(a: Future<A>, f: (Future<A>.Result)->(B)) throws -> B {
    return try f(a.resultAwait())
}

precedencegroup AsyncAlternativePrecedence {
    higherThan: AsyncForwardApplicationPrecedence
    lowerThan: ForwardCompositionPrecedence
    associativity: left
}

infix operator <||> : AsyncAlternativePrecedence

public func <||><A,B>(f: @escaping (A)->(B), g: @escaping (Error)->(B))->(Future<A>.Result)->(B) {
    return { a in
        switch a {
        case let .value(value):
            return f(value)
        case let .error(error):
            return g(error)
        }
    }
}
