module Memoize
export @memoize, @dumpf, @showf

f_parser = function(Ex::Union{Expr,Symbol}; head=:call)
        if typeof(Ex) != Expr
            return Expr(head, :(nop(nothing)), :Any)
        elseif Ex.head == head
            return Ex
        else
            return f_parser(Ex.args[1]; head=head)
        end
    end

macro memoize(f::Expr)


    Fwhere = let args = f_parser(f.args[1]; head=:where).args[2]
        :($args)
    end

    fn, fargs = let root = f_parser(f.args[1]; head=:call)
        root.args[1], root.args[2:end]
    end

    OutType = f_parser(f.args[1]; head=:(::)).args[2]
    InTypes = map(fargs) do arg
        typeof(arg)==Symbol ? :Any : arg.args[2]
    end

    block = let root = f.args[2]

        if typeof(root.args[1])!=Expr
            root.args[2]
        else
            root.args[1]
        end

    end
    
    let args=tuple(fargs...)
        esc(
            :(
                $fn = let memo = Dict{Tuple{Vararg}, $OutType}()
                    function $fn($(args...))::($OutType) where $Fwhere
                        let tpl = tuple($(args...))
                            if haskey(memo, tpl)
                                memo[tpl]
                            else 
                                get!(memo, tpl, $block)
                            end
                        end
                    end
                end
            )
        )
    end
    
end

macro dumpf(f::Expr)
    
    Fwhere = let args = f_parser(f.args[1]; head=:where).args[2]
        :($args)
    end

    fn, fargs = let root = f_parser(f.args[1]; head=:call)
        root.args[1], root.args[2:end]
    end

    OutType = f_parser(f.args[1]; head=:(::)).args[2]
    InTypes = map(fargs) do arg
        typeof(arg)==Symbol ? :Any : arg.args[2]
    end

    block = let root = f.args[2]

        if typeof(root.args[1])!=Expr
            root.args[2]
        else
            root.args[1]
        end

    end
    
    expr = let args = tuple(fargs...)
        :(
            $fn = let memo = Dict{Tuple{Vararg}, $OutType}()
                function $fn($(args...))::($OutType) where $Fwhere
                    let tpl = tuple($(args...))
                        if haskey(memo, tpl)
                            memo[tpl]
                        else 
                            get!(memo, tpl, $block)
                        end
                    end
                end
            end
        )
    end
    
    dump(expr, maxdepth=32)
end

macro showf(f::Expr)
    
    Fwhere = let args = f_parser(f.args[1]; head=:where).args[2]
        :($args)
    end

    fn, fargs = let root = f_parser(f.args[1]; head=:call)
        root.args[1], root.args[2:end]
    end

    OutType = f_parser(f.args[1]; head=:(::)).args[2]
    InTypes = map(fargs) do arg
        typeof(arg)==Symbol ? :Any : arg.args[2]
    end

    block = let root = f.args[2]

        if typeof(root.args[1])!=Expr
            root.args[2]
        else
            root.args[1]
        end

    end
    
    expr = let args = tuple(fargs...)
        :(
            $fn = let memo = Dict{Tuple{Vararg}, $OutType}()
                function $fn($(args...))::($OutType) where $Fwhere
                    let tpl = tuple($(args...))
                        if haskey(memo, tpl)
                            memo[tpl]
                        else 
                            get!(memo, tpl, $block)
                        end
                    end
                end
            end
        )
    end
    
    show(expr)
end

end
