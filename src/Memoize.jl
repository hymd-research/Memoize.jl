module Memoize

export @memoize, @dumpf, @showf


include("./Parser.jl")


macro memoize(f::Expr)
    esc(f_expr(f))    
end


macro dumpf(f::Expr)
    dump(f_expr(f), maxdepth=32)   
end


macro showf(f::Expr)   
    show(f_expr(f))  
end


end
