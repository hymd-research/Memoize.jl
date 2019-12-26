function f_parser(Ex::Union{Expr,Symbol}; head=:call)::Expr
    
    if typeof(Ex) != Expr
        return Expr(:call, :(nop(nothing)), :Any)
    elseif Ex.head == head
        return Ex
    else
        return f_parser(Ex.args[1]; head=head)
    end
end

function f_expr(f::Expr)::Expr
    Fwhere = let args = f_parser(f.args[1]; head=:where).args[2]
        if args != :Any
            :(where $args)
        else
            Symbol("")
        end
    end

    fn, fargs = let root = f_parser(f.args[1]; head=:call)
        root.args[1], root.args[2:end]
    end

    nameonly = map(fargs) do arg
        typeof(arg) == Expr ? arg.args[1] : arg
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

    let args = tuple(fargs...), argnames = tuple(nameonly...)
        :(
            $fn = let memo = Dict{Tuple{$(InTypes...)}, $OutType}()
                function $fn($(args...))::($OutType) $Fwhere
                    let tpl = tuple($(argnames...))
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
