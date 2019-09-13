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
fib = let memo=Dict{Tuple{Vararg}, BigInt}()
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
`@memoize` also works with Multiple argument function.
Example: Recursive Combination
```julia
@memoize function comb(m::T, n::T)::BigInt where{T<:Signed}
    if m<n
        0
    elseif m==0 || n==0
        1
    else
        comb(m-1, n) + comb(m-1, n-1)
    end
end
```
is equal to
```julia
comb = let memo=Dict{Tuple{Vararg}, BigInt}()
    function comb(m::T, n::T)::BigInt where T<:Signed
        let args=tuple(m::T, n::T)
            if haskey(memo, args)
                memo[args]
            else
                get!(memo, args, if m<n
                            0
                        elseif m==0 || n==0
                            1
                        else
                            comb(m-1, n) + comb(m-1, n-1)
                        end)
            end
        end
    end
end
```
