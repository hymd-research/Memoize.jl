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
function comb(m::T, n::T)::BigInt where T<:Signed

    let cache = Dict{Tuple{<:Signed, <:Signed}, BigInt}()
    
        let comb = function comb(m::T, n::T)::BigInt where T<:Signed
        
            let args=tuple(m::T, n::T)
                if haskey(cache, args)
                    cache[args]
                else
                    get!(cache, args, if m<n
                                0
                            elseif m==0 || n==0
                                1
                            else
                                comb(m-1, n) + comb(m-1, n-1)
                            end)
                end
            end
            
            comb(m, n)
        end
 
    end
    
end
 ```
