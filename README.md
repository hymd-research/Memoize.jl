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
@memoize function HyperOperator(a::T, b::T, n::T)::T where T<:Signed
    
    let succ(n::Int)::Int = n+1, inf(n::Int)::Int = n-1
        if n == 0

            if b == 0
                1
            else
                 succ(Hyper(a, inf(b), 0))
            end

        elseif n==1

            if b==0
                HyperOperator(1, inf(a), 0)
            else
                HyperOperator(a, HyperOperator(a, inf(b), n), 0)
            end

        else

            if b==1
                HyperOperator(1, inf(a), 0)
            else
                HyperOperator(HyperOperator(a, inf(b), n), a, inf(n))
            end

        end
    end
    
end
```
is equal to
```julia
function HyperOperator(a::T, b::T, n::T)::Int where T<:Signed

    let cache = Dict{Tuple{<:Signed, <:Signed, <:Signed}, BigInt}()
    
        let HyperOperator = function HyperOperator(a::T, b::T, n::T)::Int where T<:Signed
        
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
                                     succ(Hyper(a, inf(b), 0))
                                end

                            elseif n==1

                                if b==0
                                    Hyper(1, inf(a), 0)
                                else
                                    Hyper(a, Hyper(a, inf(b), n), 0)
                                end

                            else

                                if b==1
                                    Hyper(1, inf(a), 0)
                                else
                                    Hyper(Hyper(a, inf(b), n), a, inf(n))
                                end

                            end
                        end
                    )
                end
            end
            
            HyperOperator(a, b, n)
        end
 
    end
    
end
 ```
