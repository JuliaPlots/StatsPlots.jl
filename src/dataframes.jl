
# handle grouping by DataFrame column
function Plots.extractGroupArgs(group::Symbol, df::AbstractDataFrame, args...)
    Plots.extractGroupArgs(collect(df[group]))
end

# if it's one symbol, set the guide and return the column
function handle_dfs(df::AbstractDataFrame, d::KW, letter, sym::Symbol)
    get!(d, Symbol(letter * "guide"), string(sym))
    processDFarg(df, sym)
end

# if it's one symbol, set the guide and return the column
function handle_dfs(df::AbstractDataFrame, d::KW, letter, expr::Expr)
    get!(d, Symbol(letter * "guide"), replace(string(expr), ":", ""))
    processDFarg(df, expr)
end

# if it's an array of symbols, set the labels and return a Vector{Any} of columns
function handle_dfs(df::AbstractDataFrame, d::KW, letter, syms::AbstractArray)
    get!(d, :label, reshape(Symbol.(syms), 1, length(syms)))
    processDFarg(df, syms)
end

# for anything else, no-op
function handle_dfs(df::AbstractDataFrame, d::KW, letter, anything)
    anything
end

Base.hcat(a::AbstractArray, b::Number) = hcat(a, fill(b, size(a,1)))
Base.hcat(a::Number, b::AbstractArray) = hcat(fill(a, size(b,1)), b)

# allows the passing of expressions including DataFrame columns as symbols
processDFarg(df::AbstractDataFrame, sym::Symbol) = collect(df[sym])
function processDFarg(df::AbstractDataFrame, syms::AbstractMatrix)
    ret = processDFcol(df, syms[:,1])
    for i in 2:size(syms, 2)
        tmp = processDFcol(df, syms[:,i])
        ret = hcat(ret, tmp)
    end
    ret
end

processDFarg(df::AbstractDataFrame, expr::Expr) = eval(processDFsym(df, expr))
processDFarg(df::AbstractDataFrame, anything) = anything

processDFcol{T <: Union{Expr, Symbol}}(df, col::AbstractArray{T}) = processDFarg(df, col[1])
processDFcol(df, anything) = anything

# the processDFsym! functions work with expressions and pass results to processDFarg for final eval - this to allow recursion without eval
processDFsym(df::AbstractDataFrame, s::Symbol) = haskey(df,s) ? :(collect($(df)[$s])) : :($s)
processDFsym(df::AbstractDataFrame, s::QuoteNode) = haskey(df,s.value) ? :(collect($(df)[$s])) : :($s)
processDFsym(df::AbstractDataFrame, s) = :($s)

function processDFsym(df::AbstractDataFrame, expr::Expr)
    arg = map(_->processDFsym(df,_), expr.args)
    ret = copy(expr)
    ret.args = arg
    return ret
end

function processDF(d::KW, df, args...)
    # if any of these attributes are symbols, swap out for the df column
    for k in (:fillrange, :line_z, :marker_z, :markersize, :ribbon, :weights, :xerror, :yerror, :hover, :bar_width, :fill_z, :fillalpha, :fillcolor, :linealpha, :linecolor, :linestyle, :linewidth, :markeralpha, :markercolor, :markershape, :markerstrokecolor, :series_annotations, :seriesalpha, :seriescolor)
        if haskey(d, k)
            d[k] = processDFarg(df, d[k])
        end
    end

    # return a list of new arguments
    d, tuple(Any[handle_dfs(df, d, (i==1 ? "x" : i==2 ? "y" : "z"), arg) for (i,arg) in enumerate(args)]...)
end

# if a DataFrame is the first arg, lets swap symbols out for columns
@recipe function f(df::AbstractDataFrame, args...)
    d, args = processDF(d, df, args...)
    args
end
