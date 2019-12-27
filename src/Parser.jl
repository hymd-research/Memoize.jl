struct FunctionExpr
    fn::Symbol,
    fargs::Array{T,1} where T,
    output::Symbol,
    whstmt::Array{T,1} where T,
    argnames::Tuple{Vararg{Symbol}},
    template::Union{Expr, Symbol}
end

function f_parser(Ex::Union{Expr,Symbol}; head=:call)::Expr
    
    if typeof(Ex) != Expr
        return Expr(:(::), :(nop(nothing)), :Any)
    elseif Ex.head == head
        return Ex
    else
        return f_parser(Ex.args[1]; head=head)
    end
    
end

function f_header(e::FunctionExpr)::Expr
    
    if (e.output == :Any) && isempty(e.whstmt)
        let call = :($fn($(e.fargs...)))
            :(function $call end)
        end
    elseif isempty(e.whstmt)
        let call = :($fn($(e.fargs...))::$e.output)
            :(function $call end)
        end
    else
        let call = :($fn($(e.fargs...))::$e.output), cpwhere = copy(e.whstmt)
            while !isempty(cpwhere)
                annotation = pop!(cpwhere)
                call = :($call where $annotation)
            end
            :(function $call end)
        end
    end
    
end


function f_closure(e::FunctionExpr)::Expr
    
    let closure = f_header(e)
        
        push!(closure.args, e.template)
        closure
        
    end
    
end

function f_expr(f::Expr)::Expr
    
    if f.head != :function
        throw(Meta.ParseError("First keyword must be :function given $(f.head)"))
    end
    
    whstmt = let node=f.args[1], annotations = []
        while node.head==:where
            typeinfo = f_parser(node; head=:where).args[2]
            push!(annotations, typeinfo)
            node = node.args[1]
        end
        annotations
    end
    
    type_annotations = if isempty(whstmt) 
        Dict()
    else
        Dict(ex.args[1] => (ex.head, ex.args[2]) for ex in whstmt)
    end

    fn, fargs = let root = f_parser(f.args[1]; head=:call)
        root.args[1], root.args[2:end]
    end
    
    argnames = let nameonly = map(fargs) do arg
            typeof(arg) == Expr ? arg.args[1] : arg
        end
        tuple(nameonly...)
    end

    OutType = f_parser(f.args[1]; head=:(::)).args[2]
    
    InTypes = map(fargs) do arg
        name = typeof(arg)==Symbol ? :Any : f_parser(arg, head=:(::)).args[2]
        if isempty(type_annotations) || !haskey(type_annotations, name)
            name
        else
            op, tp = get(type_annotations, name, (:(<:), :Any))
            Expr(op, tp)
        end
    end

        let = block = let root = f.args[2]
            if typeof(root.args[1])!=Expr
                root.args[2]
            else
                root.args[1]
            end
        end
    
    template = let = block = 
            let root = f.args[2]
                if typeof(root.args[1])!=Expr
                    root.args[2]
                else
                    root.args[1]
                end
            end
            
        :(
            let tpl = tuple($(argnames...))
                if haskey(cache, tpl)
                    cache[tpl]
                else
                    get!(
                        cache, tpl, 
                        $block
                    )
                end
            end
        )
        end
    end

    let fexpr = FunctionType(fn, fargs, OutType, copy(whstmt), argnames, template)
        let f_decstmt = f_header(fexpr), f_block = f_closure(fexpr)
            push!(
                f_decstmt.args,
                :(
                    
                    let cache = Dict{Tuple{$(InTypes...)}, $OutType}()
                        
                        let $fn = $f_block
                            
                            $fn($(argnames...))
                            
                        end
                        
                    end
                )
            )
            
            return f_decstmt
        end
    end

end
