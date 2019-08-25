# Memoize.jl
Macro for memoizing recursive functions.

## Sample
```Julia>=1.1.1
@memoize function fib(n::T)::BigInt where {T<:Signed}
  n<2 ? n : fib(n-1) + fib(n-2)
end
```
The function above is going to be evaluated as below.
```Julia>=1.1.1
function fib(n::T; memo=Dict{T, BigInt}())::BigInt where {T<:Signed}
  if haskey(memo, (n,))
    memo[(n,)]
  else
    get!(
      memo,
      (n,),
      begin
        if n<2
          n
        else
          fib(n-1, memo=memo) + fib(n-2, memo=memo)
        end
      end
      )
  end
end
```
