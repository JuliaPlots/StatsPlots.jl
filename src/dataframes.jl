
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
function extractGroupArgs(group::Symbol, df::AbstractDataFrame, args...)
    extractGroupArgs(collect(df[group]))
end

# if a DataFrame is the first arg, lets swap symbols out for columns
@recipe function f(df::AbstractDataFrame, args...)
    # if any of these attributes are symbols, swap out for the df column
    for k in (:fillrange, :line_z, :marker_z, :markersize, :ribbon, :weights, :xerror, :yerror)
        if haskey(d, k) && isa(d[k], Symbol)
            d[k] = collect(df[d[k]])
        end
    end

    # return a list of new arguments
    tuple(Any[handle_dfs(df, d, (i==1 ? "x" : i==2 ? "y" : "z"), arg) for (i,arg) in enumerate(args)]...)
end
