import Foundation

// A bunch of convenience things
func const <A, B> (b: B) -> (A) -> B {
    return { _ in b }
}
func repetition <A> (n: Int) -> (A) -> [A] {
    return { a in
        return [0...n].map(const(b: a))
    }
}

precedencegroup ComparisonPrecedence {
    associativity: left
    //higherThan: LogicalConjunctionPrecedence
}
infix operator |> : ComparisonPrecedence
func |> <A, B> (x: A, f: (A) -> B) -> B {
    return f(x)
}
func |> <A, B, C> (f: @escaping (A) -> B, g: @escaping (B) -> C) -> (A) -> C {
    return { g(f($0)) }
}
func append <A> (xs: [A], x: A) -> [A] {
    return xs + [x]
}
func square (x: Int) -> Int {
    return x*x
}
func isPrime (p: Int) -> Bool {
    if p <= 1 { return false }
    if p <= 3 { return true }
    for i in 2...Int(sqrtf(Float(p))) {
        if p % i == 0 {
            return false
        }
    }
    return true
}
func incr (x: Int) -> Int {
    return x + 1
}


// Here's the good stuff

class Transducer <A, B> {
    func step <R> (_: @escaping (R, A) -> R) -> (R, B) -> R {
        fatalError("should be overriden")
    }
}

class CompositionTransducer <A, B, C> : Transducer <A, C> {
    let lhs: Transducer<B, C>
    let rhs: Transducer<A, B>
    
    init (_ lhs: Transducer<B, C>, _ rhs: Transducer<A, B>) {
        self.lhs = lhs
        self.rhs = rhs
    }
    
    override func step <R> (_ reducer: @escaping (R, A) -> R) -> (R, C) -> R {
        return self.lhs.step(self.rhs.step(reducer))
    }
}

func |> <A, B, R> (reducer: @escaping (R, A) -> R, transducer: Transducer<A, B>) -> (R, B) -> R {
    return transducer.step(reducer)
}

func |> <A, B, C> (lhs: Transducer<A, B>, rhs: Transducer<B, C>) -> Transducer<A, C> {
    return CompositionTransducer<A, B, C>(rhs, lhs)
}

class Mapping <B, A> : Transducer <B, A> {
    var f: (A) -> B
    init(_ f: @escaping (A) -> B) {
        self.f = f
    }
    
    override func step <R> (_ reducer: @escaping (R, B) -> R) -> (R, A) -> R {
        return { accum, a in
            return reducer(accum, self.f(a))
        }
    }
}

class FlatMapping <B, A> : Transducer <B, A> {
    let f: (A) -> [B]
    init(_ f: @escaping (A) -> [B]) {
        self.f = f
    }
    
    override func step <R> (_ reducer: @escaping (R, B) -> R) -> (R, A) -> R {
        return { accum, a in
            // return reduce(self.f(a), accum, reducer)
            return self.f(a).reduce(accum, reducer)
        }
    }
}

class Filtering <A> : Transducer <A, A> {
    let p: (A) -> Bool
    init (_ p: @escaping (A) -> Bool) {
        self.p = p
    }
    
    override func step <R> (_ reducer:  @escaping (R, A) -> R) -> (R, A) -> R {
        return { accum, a in
            return self.p(a) ? reducer(accum, a) : accum
        }
    }
}

//  Chris Eidhof, Florian Kugler, and Wouter Swierstra
let xs = Array(1...10)
xs.reduce([], append |> Filtering(isPrime) |> Mapping(square |> incr))

let ms = Array(1...10)
ms.reduce( [],
           append
            |> FlatMapping(repetition(n: 1))
            |> Filtering(isPrime)
            |> Mapping(square |> incr)
)


let compositeTransducer = FlatMapping(repetition(n:1)) |> Filtering(isPrime) |> Mapping(square |> incr)
xs.reduce( 0, (+) |> compositeTransducer)





