# Memoize.jl
Macro for memoizing recursive functions.

## Sample
```julia
@memoize function fib(n::T)::BigInt where {T<:Signed}
    n<2 ? n : fib(n-1) + fib(n-2)
end
```
The function above is to be evaluated as below.
```julia
function fib(n::T)::BigInt where T<:Signed

    let cache = Dict{Tuple{<:Signed}, BigInt}()
    
        let fib = function fib(n::T)::BigInt where T<:Signed
        
            let args = tuple(n)
                if haskey(cache, args)
                    cache[args]
                else
                    get!(cache, args, if n<2
                                n
                            else
                                fib(n-1)+fib(n-2)
                            end)
                end
            end
            
            fib(n)
        end
        
    end
    
end
```
`@memoize` also works with Multiple argument function.
Example: [HyperOperator](https://en.wikipedia.org/wiki/Hyperoperation)
```julia
@memoize function Hyper(n::T, a::T, b::T)::T where T<:Signed
    
    let succ(n::Int)::Int = n+1, inf(n::Int)::Int = n-1
        if n == 0

            if b == 0
                1
            else
                 succ(Hyper(0, a, inf(b)))
            end

        elseif n==1

            if b==0
                Hyper(0, 1, inf(a))
            else
                Hyper(0, a, Hyper(n, a, inf(b)))
            end

        else

            if b==1
                Hyper(0, 1, inf(a))
            else
                Hyper(inf(n), Hyper(n, a, inf(b)), a)
            end

        end
    end
    
end
```
is equal to
```julia
function Hyper(n::T, a::T, b::T)::T where T<:Signed

    let cache = Dict{Tuple{<:Signed, <:Signed, <:Signed}, BigInt}()
    
        let HyperOperator = function Hyper(n::T, a::T, b::T)::T where T<:Signed
        
            let args=tuple(a, b, n)
                if haskey(cache, args)
                    cache[args]
                else
                    get!(
                        cache, args, 
                        let succ(n::Int)::Int = n+1, inf(n::Int)::Int = n-1
                                if n == 0

                                    if b == 0
                                        1
                                    else
                                         succ(Hyper(0, a, inf(b)))
                                    end

                                elseif n==1

                                    if b==0
                                        Hyper(0, 1, inf(a))
                                    else
                                        Hyper(0, a, Hyper(n, a, inf(b)))
                                    end

                                else

                                    if b==1
                                        Hyper(0, 1, inf(a))
                                    else
                                        Hyper(inf(n), Hyper(n, a, inf(b)), a)
                                    end

                                end
                            end
                    )
                end
            end
            
            Hyper(n, a, b)
        end
 
    end
    
end
 ```
