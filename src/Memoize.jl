module Memoize
export @memoize

macro memoize(f)

    head_parser = function(Ex::Union{Expr,Symbol}; head=:call)
        if typeof(Ex) != Expr
            return Expr(head, :(nop(nothing)), :Any)
        elseif Ex.head == head
            return Ex
        else
            return head_parser(Ex.args[1]; head=head)
        end
    end


    Fwhere = let args = head_parser(f.args[1]; head=:where).args[2]
        :($args)
    end

    fn, fargs = let root = head_parser(f.args[1]; head=:call)
        root.args[1], root.args[2:end]
    end

    OutType = head_parser(f.args[1]; head=:(::)).args[2]
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
        @eval $fn = let memo = Dict{$(Expr(:curly, :Tuple, InTypes...)), $OutType}()
            function $fn($(args[1]), $(args[2:end] ...))::($OutType) where $Fwhere
                let tpl = ($(args[1]), $(args[2:end] ...))
                    if haskey(memo, tpl)
                        memo[tpl]
                    else
                        get!(memo, tpl, $block)
                    end
                end
            end
        end
    end

end
end
