module Memoize
export @memoize

macro memoize(f)


    argnames, argtypes = begin
        root = f.args[1]

        while root.head!=:call
            root = root.args[1]
        end

        args = root.args[2:length(root.args)]

        args, map(ex->typeof(ex)==Expr ? ex.args[2] : :Any, args)
    end


    fname, ftype = begin
        root = f.args[1]
        fname, ftype = :Symbol, :Symbol
        while root.head!=:call
            if root.head == :(::)

                ftype = root.args[2]
            end
            root = root.args[1]
        end
        fname = root.args[1]

        insert!(
            root.args,
            2,
            Expr(
                :parameters,
                Expr(
                    :kw,
                    :memo,
                    Expr(
                        :call,
                        Expr(
                            :curly,
                            :Dict,
                            Expr(
                                :curly,
                                :Tuple,
                                argtypes...
                                ),
                            ftype
                            )
                        )
                    )
                )
        )
        fname, ftype
    end

    f.args[2] = begin
        root = f.args[2]

        stack=[root]
        while !isempty(stack)
            root = pop!(stack)
            if typeof(root)==Expr
                if root.args[1] == fname
                    push!(root.args, Expr(:kw, :memo, :memo))
                end

                nodes=filter(ex->typeof(ex)==Expr, root.args)

                while !isempty(nodes)
                    push!(stack, pop!(nodes))
                end
            end
        end

        f.args[2]
    end

    f.args[2] =
    :(
        let args=tuple($(argnames...))
            if haskey(memo, args)
                memo[args]
            else
                get!(memo, args, $(f.args[2]))
            end
        end
    )

    @eval $f

end
end
