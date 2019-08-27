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


    root = head_parser(f.args[1]; head=:where)
    f_where = let args = root.args[2]
        :($args)
    end

    root = head_parser(f.args[1]; head=:(::))
    f_type = root.args[2]

    root = head_parser(f.args[1]; head=:call)
    f_name = root.args[1]
    f_args = root.args[2:end]

    f_args_types = map(f_args) do args
        typeof(args)==Symbol ? :Any : args.args[2]
    end

    f_block = let root = f.args[2]

        if typeof(root.args[1])!=Expr
            root.args[2]
        else
            root.args[1]
        end

    end

    let args=tuple(f_args...)
        @eval $f_name = let memo = Dict{$(Expr(:curly, :Tuple, f_args_types...)), $f_type}()
            function $f_name($(args[1]), $(args[2:end] ...))::($f_type) where $f_where
                let tpl = ($(args[1]), $(args[2:end] ...))
                    if haskey(memo, tpl)
                        memo[tpl]
                    else
                        get!(memo, tpl, $f_block)
                    end
                end
            end
        end
    end

end
end
