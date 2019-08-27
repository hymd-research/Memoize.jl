# Memoize.jl
Macro for memoizing recursive functions.

## Sample
```julia
@memoize function fib(n::T)::BigInt where {T<:Signed}
    n<2 ? n : fib(n-1) + fib(n-2)
end
```
The function above is going to be evaluated as below.
```diff
-function fib(n::T; memo=Dict{T, BigInt}())::BigInt where {T<:Signed}
+fib =
+let memo=Dict{$(Expr(:curly, :Tuple, f_args_types...)), BigInt}()
+    function fib(n::T)::BigInt where T<:Signed
+        let args = tuple(n::T,)
            if haskey(memo, args)
                memo[args]
            else
                get!(
                    memo,
                    args,
-                    begin
                      if n<2
                        n
                      else
-                        fib(n-1, memo=memo) + fib(n-2, memo=memo)
+                        fib(n-1) + fib(n-1)
                      end
-                    end
                    )
            end
+        end
+    end
end
```
