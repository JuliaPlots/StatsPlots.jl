
# if it's one symbol, set the guide and return the column
function handle_dfs(df::AbstractDataFrame, d::KW, letter, sym::Symbol)
    get!(d, Symbol(letter * "guide"), string(sym))
    collect(df[sym])
end

# if it's an array of symbols, set the labels and return a Vector{Any} of columns
function handle_dfs(df::AbstractDataFrame, d::KW, letter, syms::AbstractArray{Symbol})
    get!(d, :label, reshape(syms, 1, length(syms)))
    Any[collect(df[s]) for s in syms]
end

# for anything else, no-op
function handle_dfs(df::AbstractDataFrame, d::KW, letter, anything)
    anything
end

# handle grouping by DataFrame column
function Plots.extractGroupArgs(group::Symbol, df::AbstractDataFrame, args...)
    Plots.extractGroupArgs(collect(df[group]))
end

# allows the passing of expressions including DataFrame columns as symbols
function processExpr!(expr, df)
    arg = map(expr.args) do x
        isa(x, Expr) && return processExpr!(x, df)

        if isa(x, QuoteNode) && isa(x.value, Symbol)
            return :(collect($(df)[$x]))
        end
        x
    end
    expr.args = arg
    return expr
end

# if a DataFrame is the first arg, lets swap symbols out for columns
@recipe function f(df::AbstractDataFrame, args...)
    # if any of these attributes are symbols, swap out for the df column
    for k in (:fillrange, :line_z, :marker_z, :markersize, :ribbon, :weights, :xerror, :yerror, :hover)
        if haskey(d, k)
            if isa(d[k], Expr)
                d[k] = eval(processExpr!(d[k], df))
            end

            if isa(d[k], Symbol)
                d[k] = collect(df[d[k]])
            end
        end
    end

    # return a list of new arguments
    tuple(Any[handle_dfs(df, d, (i==1 ? "x" : i==2 ? "y" : "z"), arg) for (i,arg) in enumerate(args)]...)
end
