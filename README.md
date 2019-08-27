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
fib = let memo=Dict{Tuple{T}, BigInt}()
    function fib(n::T)::BigInt where T<:Signed
        let args=tuple(n::T)
            if haskey(memo, args)
                memo[args]
            else
                get!(memo, args, if n<2
                            n
                        else
                            fib(n-1)+fib(n-2)
                        end)
            end
        end
    end
end
```
