function f_parser(Ex::Union{Expr,Symbol}; head=:call)::Expr
    
    if typeof(Ex) != Expr
        return Expr(:(::), :(nop(nothing)), :Any)
    elseif Ex.head == head
        return Ex
    else
        return f_parser(Ex.args[1]; head=head)
    end
    
end

function f_template(
        fn::Symbol, 
        fargs::Array{T, 1} where T, 
        output::Symbol, 
        whstmt::Array{T, 1} where T, 
        argnames::Tuple{Vararg{Symbol}}, 
        block::Union{Expr, Symbol})::Expr
    
    template = :(
        let tpl = tuple($(argnames...))
            if haskey(memo, tpl)
                memo[tpl]
            else
                get!(memo, tpl, $block)
            end
        end
    )
    
    f_header = if (output == :Any) && isempty(whstmt)
        :(function $fn($(fargs...)) end)
    elseif whstmt == isempty(whstmt)
        :(function $fn($(fargs...))::$output end)
    else
        let call = :($fn($(fargs...))::$output)
            while !isempty(whstmt)
                annotation = pop!(whstmt)
                call = :($call where $annotation)
            end
            :(function $call end)
        end
    end
        
    push!(f_header.args[2].args, template)
        
    f_header
    
end

function f_expr(f::Expr)::Expr
    
    whstmt = let node=f.args[1], annotations = []
        while node.head==:where
            typeinfo = f_parser(node; head=:where).args[2]
            push!(annotations, typeinfo)
            node = node.args[1]
        end
        annotations
    end
    
    type_annotations = !isempty(whstmt) && Dict(ex.args[1] => (ex.head, ex.args[2]) for ex in whstmt)

    fn, fargs = let root = f_parser(f.args[1]; head=:call)
        root.args[1], root.args[2:end]
    end
    
    nameonly = map(fargs) do arg
        typeof(arg) == Expr ? arg.args[1] : arg
    end

    OutType = f_parser(f.args[1]; head=:(::)).args[2]
    
    InTypes = map(fargs) do arg
        name = typeof(arg)==Symbol ? :Any : f_parser(arg, head=:(::)).args[2]
        if typeof(type_annotations) == Bool
            name
        elseif haskey(type_annotations, name)
            op, tp = get(type_annotations, name, (:(<:), :Any))
            Expr(op, tp)
        end
    end

    block = let root = f.args[2]
        if typeof(root.args[1])!=Expr
            root.args[2]
        else
            root.args[1]
        end
    end

    let argnames = tuple(nameonly...)
        :(
            $fn = let memo = Dict{Tuple{$(InTypes...)}, $OutType}()
                $(f_template(fn, fargs, OutType, whstmt, argnames, block))
            end
        )
    end

end
