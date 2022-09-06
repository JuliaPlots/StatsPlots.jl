
using StatsAPI: RegressionModel, StatisticalModel
using StatsModels: 
    TableRegressionModel,
    AbstractTerm,
    CategoricalTerm,
    InteractionTerm,
    formula,
    coef,
    coefnames,
    stderror,
    confint

### Util functions for StatsModels/StatsAPI types

# Type-piracy, call it responsename__ instead of StatsAPI.responsename
responsename__(m::StatisticalModel) = coefnames(formula(m).lhs)

function baselevel(ct::CategoricalTerm)
    b = [string(e) for e in ct.contrasts.levels if !in(e, ct.contrasts.termnames)]
    if length(b) == 0
        return ""
    elseif length(b) == 1
        return b[1]
    else
        @error "the category cannot have more than one base level: $(b)"
    end
end

baselevelname(ct::CategoricalTerm) = "$(ct.sym): $(baselevel(ct))"

allcoefnames(t::CategoricalTerm) = t.contrasts.levels
allcoefnames(t::InteractionTerm) =
    kron_insideout((args...) -> join(args, " & "), vectorize.(allcoefnames.(t.terms))...)
allcoefnames(t::AbstractTerm) = coefnames(t)

rawcoefnames(t::CategoricalTerm) = t.contrasts.termnames
rawcoefnames(t::InteractionTerm) =
    kron_insideout((args...) -> join(args, " & "), vectorize.(rawcoefnames.(t.terms))...)
rawcoefnames(t::AbstractTerm) = coefnames(t)

catcoefnames(t::CategoricalTerm) = string(t.sym)
catcoefnames(t::InteractionTerm) = join(catcoefnames.(t.terms), " & ")
catcoefnames(t::AbstractTerm) = coefnames(t)

defined_methods = (formula, coef, coefnames, stderror)
check_type(m) =
    (isa(m, StatisticalModel) && all(hasmethod(f, (typeof(m),)) for f in defined_methods))
check_type_confint(m) = hasmethod(confint, (typeof(m),))

### Util functions for grouping the terms

struct ForestTerm{T<:AbstractFloat}
    term::String
    name::String
    coef::T
    error::Union{T, Tuple{T, T}}
    weight::Float64

    function ForestTerm{T}(
            term::AbstractString,
            name::AbstractString,
            coef::T,
            error::Union{T, Tuple{T, T}},
            weight::Float64,
        ) where {T <: AbstractFloat}
        return new(string(term), string(name), coef, error, weight)
    end
end

function ForestTerm(
        term::AbstractString,
        name::AbstractString,
        coef::Real,
        error::Union{Tuple{<:Real, <:Real}, <:Real},
        weight::Union{Integer, AbstractFloat} = 1,
    )
    return ForestTerm{Float64}(term, name, convert(Float64, coef), convert.(Float64, error), convert(Float64, weight))
end

ModelTerm = @NamedTuple{term::String, variables::Vector{String}, indices::Vector{Int}}
ModelTree = Vector{ModelTerm}


"""
    get_modeltree(terms::AbstractVector{<:ForestTerm})::ModelTree

Convert a vector of ForestTerm to a ModelTree (Vector of ModelTerm).
The ModelTree can be later used for merging two or more models.

"""
function get_modeltree(terms::AbstractVector{<:ForestTerm})::ModelTree
    modeltree = ModelTree()
    current_term = nothing
    current_group = String[]
    i = 1
    for t in terms
        if t.term != current_term
            if !isnothing(current_term)
                inds = collect(i:(i+length(current_group)-1))
                # save previous terms
                modelterm = (; term=current_term, variables=current_group, indices=inds)
                push!(modeltree, modelterm::ModelTerm)
            end
            i += length(current_group)
            current_term = t.term
            current_group = String[]
        end
        push!(current_group, t.name)
    end
    if !isnothing(current_term)
        # save last terms
        inds = collect(i:(i+length(current_group)-1))
        modelterm = (; term=current_term, variables=current_group, indices=inds)
        push!(modeltree, modelterm::ModelTerm)
    end

    return modeltree
end

"""
    get_terms_from_model(
        m::StatisticalModel;
        intercept::Bool = false,
        useconfint::Bool = true,
        level::Real = 0.95,
    )::Tuple

Returns four vectors from the StatisticalModel:
- a vector of AbstractTerms from the formula
- a vector of coefficient names
- a vector of coefficient values
- a vector of coefficient error values (float or tuple of floats)

The lengths of the last three vectors are identical, the length of the
first vector is less or equal the the other (it is less if there are categorical terms).

"""
function get_terms_from_model(
        m::StatisticalModel;
        intercept::Bool = false,
        useconfint::Bool = true,
        level::Real = 0.95,
    )::Tuple

    # skip first term is intercept is false
    firstind = (intercept || !hasintercept(formula(m))) ? 1 : 2

    # get terms without baselevel in Categorical terms
    model_names = coefnames(m)[firstind:end]
    model_coefs = coef(m)[firstind:end]
    if useconfint
        model_errors = [tuple(x...) for x in eachrow(confint(m; level))][firstind:end]
        # these are confidence intervals, convert to error relative to coefs (tuple of two positive values)
        for i in eachindex(model_errors, model_coefs)
            model_errors[i] = abs.(model_errors[i] .- model_coefs[i])
        end
    else
        factor = quantile(Normal(), (1 - level) / 2)
        model_errors = stderror(m)[firstind:end] .* factor
    end
    # get all terms from the model
    model_terms = formula(m).rhs.terms[firstind:end]
    # do not take into account constant terms (like 0 and -1 to remove intercept)
    model_terms = [t for t in model_terms if length(coefnames(t)) > 0]

    return model_terms, model_names, model_coefs, model_errors
end

"""
    create_forest_terms_no_grouping(
        m::StatisticalModel;
        intercept::Bool = false,
        useconfint::Bool = true,
        level::Real = 0.95,
        model::AbstractString = "",
    )::Vector{ForestTerm}

Returns the terms to plot from a StatisticalModel, that is
a Vector of ForestTerm.

"""
function create_forest_terms_no_grouping(
        m::StatisticalModel;
        intercept::Bool = false,
        useconfint::Bool = true,
        level::Real = 0.95,
    )::Vector{ForestTerm}

    # get all terms from the model
    _, model_names, model_coefs, model_errors =
        get_terms_from_model(m; intercept, useconfint, level)

    groups = [
        ForestTerm(model_names[i], model_names[i], model_coefs[i], model_errors[i])
        for i in eachindex(model_names, model_coefs, model_errors)
    ] 
    return groups
end


"""
    create_forest_terms(
        m::StatisticalModel;
        intercept::Bool = false,
        headers::Bool = false,
        add_category_first::Bool = true,
        useconfint::Bool = true,
        level::Real = 0.95,
        model::AbstractString = "",
    )::Vector{ForestTerm}

Returns the terms to plot from a StatisticalModel, that is
a Vector of ForestTerm.

"""
function create_forest_terms(
        m::StatisticalModel;
        intercept::Bool = false,
        headers::Bool = false,
        add_category_first::Bool = true,
        useconfint::Bool = true,
        level::Real = 0.95,
    )::Vector{ForestTerm}

    # get all terms from the model
    model_terms, model_names, model_coefs, model_errors =
        get_terms_from_model(m; intercept, useconfint, level)

    # if no grouping per category, use one term = one variable.
    if !headers
        groups = [
            ForestTerm(model_names[i], model_names[i], model_coefs[i], model_errors[i])
            for i in eachindex(model_names, model_coefs, model_errors)
        ] 
        return groups
    end

    nterms = length(model_terms)
    # partition coefs by terms
    n_coef_terms = [length(t) for t in vectorize.(coefnames.(model_terms))]
    @assert sum(n_coef_terms) == length(model_names)

    # split the coef by formula term, group together the categorical variables
    # ex:
    # term_names = [["(Intercept)"], ["SepalLength"], ["Species: versicolor", "Species: virginica"]]
    # term_coefs = [[0.8030518051301283], [0.1316316809568254], [-0.6179362956010999, -0.19258382483428874]]
    cs = cumsum(n_coef_terms)
    ss = cs .- n_coef_terms .+ 1
    part = [ss[i]:cs[i] for i in eachindex(ss, cs)]
    term_names = map(p -> model_names[p], part)
    term_coefs = map(p -> model_coefs[p], part)
    term_errors = map(p -> model_errors[p], part)

    # Iterate over formula terms and add a ForestTerm per category
    groups = ForestTerm[]
    for j in eachindex(collect(model_terms), term_names, term_coefs, term_errors)
        current_term = model_terms[j]
        term_name = catcoefnames(current_term)

        # coef name, value and error; grouped by formula term
        current_term_names = term_names[j]
        current_term_coefs = term_coefs[j]
        current_term_errors = term_errors[j]
        n_terms = length(current_term_coefs)

        # Iterate over terms
        # CategoricalTerm: retrieve base level
        if isa(current_term, CategoricalTerm)
            category_terms = current_term.contrasts.termnames
            first = false
            if isa(current_term.contrasts.contrasts, StatsModels.FullDummyCoding)
                # skip as there is no base level, all coef are computed
                if add_category_first
                    first = true
                end
            else
                # Add base level - set coef to 0
                if add_category_first
                    var_name = baselevelname(current_term)
                else
                    var_name = baselevel(current_term)
                end
                push!(groups, ForestTerm(term_name, var_name, 0, 0))
            end

            # Add other levels with a coef estimated by the model
            for idx in eachindex(category_terms, current_term_coefs, current_term_errors)
                var_name = string(category_terms[idx])
                if first
                    first = false
                    var_name = "$(current_term.sym): $(var_name)"
                end
                coef = current_term_coefs[idx]
                error = current_term_errors[idx]
                push!(groups, ForestTerm(term_name, var_name, coef, error))
            end
            
        # InteractionTerm: retrieve base level
        elseif isa(current_term, InteractionTerm)
            allcoefs = allcoefnames(current_term)
            rawcoefs = rawcoefnames(current_term)
            if length(rawcoefs) != n_terms
                mess = ("the number of interaction terms differs from "*
                        "what was found using all categorical levels:\n"*
                        "$(current_term_names) != $(rawcoefs)")
                @warn(mess)
            end
            first = true
            remaining_idx = collect(1:n_terms)
            for var_name in allcoefs
                idx = findfirst(x -> x == var_name, rawcoefs)
                if add_category_first && first
                    var_name = "$(term_name): $(var_name)"
                    first = false
                else
                    var_name = string(var_name)
                end
                if isnothing(idx)
                    # Add base level - set coef to 0
                    push!(groups, ForestTerm(term_name, var_name, 0, 0))
                else
                    if !in(idx, remaining_idx)
                        @warn "trying to plot an interaction level twice: $(var_name)"
                    end
                    # Add other levels with a coef estimated by the model
                    coef = current_term_coefs[idx]
                    error = current_term_errors[idx]
                    push!(groups, ForestTerm(term_name, var_name, coef, error))
                    deleteat!(remaining_idx, findfirst(x -> x == idx, remaining_idx))
                end
            end
            if length(remaining_idx) != 0
                @warn "some interaction levels were not shown: $(current_term_names[remaining_idx])"
            end

        # single term: no special treatment
        elseif n_terms == 1
            var_name = only(current_term_names)
            coef = only(current_term_coefs)
            error = only(current_term_errors)
            push!(groups, ForestTerm(term_name, var_name, coef, error))

        # no term: skip, for instance constants to remove intercept
        elseif n_terms == 0
        else
            @warn "cannot parse term, skipping: $(current_term)"
        end
    end
    return groups
end


"""
    term_spacing(
        terms::AbstractVector{ForestTerm};
        term_width::Real = 1.0,
        incategory_width::Real = 0.5,
        offset::Real = term_width / 2,
    )

Returns a vector of the spaces between the terms in the plot.
The vector length is the same as the number of terms.
If the length is non-zero, the first value is set to `offset`
(space between the origin and the first term).

"""
function term_spacing(
    terms::AbstractVector{ForestTerm};
    term_width::Real = 1.0,
    incategory_width::Real = 0.5,
    offset::Real = term_width / 2,
)::Vector{Float64}
    # vector of spacing between terms
    h = Float64[]
    current_term = nothing
    for t in terms
        if t.term != current_term
            if isnothing(current_term)
                # first term
                push!(h, offset)
            else
                # new term
                push!(h, term_width)
            end
            current_term = t.term
        else
            # new category from the same term
            push!(h, incategory_width)
        end
    end
    return h
end

function term_spacing(
    groups::ModelTree;
    term_width::Real = 1.0,
    incategory_width::Real = 0.5,
    offset::Real = term_width / 2,
)::Vector{Float64}
    # vector of spacing between terms
    h = Float64[]
    first_term = true
    for mt in groups
        vars = mt.variables
        if first_term
            # first term
            push!(h, offset)
            first_term = false
        else
            # new term
            push!(h, term_width)
        end
        if length(vars) > 1
            for _ = 2:length(vars)
                push!(h, incategory_width)
            end
        end
    end
    return h
end


"""
    get_plotting_values(
        m::RegressionModel;
        intercept::Bool = false,
        headers::Bool = false,
        useconfint::Bool = true,
        level::Real = 0.95,
        term_width::Real = 1.0,
        incategory_width::Real = 0.5,
        offset::Real = term_width / 2,
        add_category_first::Bool = true,
        model_name::AbstractString = "",
    )

Gather all the information from the model to make the coefplot.

"""
function get_plotting_values(
    m::StatisticalModel;
    intercept::Bool = false,
    headers::Bool = false,
    useconfint::Bool = true,
    level::Union{Real, AbstractVector{<:Real}},
    term_width::Real = 1.0,
    incategory_width::Real = 0.5,
    offset::Real = term_width / 2,
    group_offset::Real = incategory_width / length(ms),
    strict_names_order::Bool = false,
)
    title = responsename__(m)
    terms = create_forest_terms(m; intercept, headers, useconfint, level, add_category_first=true)
    names = [t.name for t in terms]
    coefs = [t.coef for t in terms]
    errors = [t.error for t in terms]
    yvals = cumsum(term_spacing(terms; term_width, incategory_width, offset))

    return yvals, names, coefs, errors, title
end


"""
    merge_models(
        models::AbstractVector{ModelTree},
        strict_names_order::Bool = false,
    )::ModelTree

Merging the model terms trees as the union of term name and vector of variable names.
If `strict_names_order` is true, compare variable names in the same order, otherwise compare
variable names without taking into account the order of the variables.

E.g.:
model_tree_1 = [(; term="x", variables=["x"]), (; term="cat", variables=["b", "a"])]
model_tree_2 = [(; term="x", variables=["x"]), (; term="cat", variables=["a", "b"]), (; term="x & cat", variables=["x & a", "x & b"])]
merged_model_no_strict_names_order = [(; term="x", variables=["x"]), (; term="cat", variables=["b", "a"]), (; term="x & cat", variables=["x & a", "x & b"])]
merged_model_strict_names_order = [(; term="x", variables=["x"]), (; term="cat", variables=["b", "a"]), (; term="cat", variables=["a", "b"]), (; term="x & cat", variables=["x & a", "x & b"])]

"""
function merge_models(
    models::AbstractVector{ModelTree};
    strict_names_order::Bool = false,
)::ModelTree
    container = strict_names_order ? identity : Set
    allterms = ModelTree()
    for modeltree in models
        for modelterm in modeltree
            m = findall(x->x.term == modelterm.term && container(x.variables) == container(modelterm.variables), allterms)
            if length(m) == 0
                mt = (; term=modelterm.term, variables=modelterm.variables, indices=Int[])
                push!(allterms, mt)
            end
        end
    end

    # Compute indices
    i = 1
    for t in allterms
        iend = i + length(t.variables) - 1
        append!(t.indices, i:iend)
        i = iend + 1
    end
    return allterms
end

"""
    find_indices(modelterm::ModelTerm, groups::ModelTree; strict_names_order::Bool = false)

Find the indices in the `groups` ModelTree matching the given `modelterm`.
If `strict_names_order` is true, match the variable names in the same order as in the given
`modelterm`, otherwise match if the term has the same variable names, irrespective of the order
of the variable names.
"""
function find_indices(modelterm::ModelTerm, groups::ModelTree; strict_names_order::Bool = false)
    container = strict_names_order ? identity : Set
    for t in groups
        if t.term == modelterm.term && container(t.variables) == container(modelterm.variables)
            # reorder indices
            if !strict_names_order
                p = [only(findall(==(name), modelterm.variables)) for name in t.variables]
                inds = t.indices[p]
            else
                inds = t.indices
            end
            return inds
        end
    end
    # Should never happen
    return nothing
end

"""
    get_merged_plotting_values(
        ms::AbstractVector{<:RegressionModel};
        intercept::Bool = false,
        headers::Bool = false,
        useconfint::Bool = true,
        level::Real = 0.95,
        term_width::Real = 1.0,
        incategory_width::Real = 0.5,
        offset::Real = term_width / 2,
        group_offset::Real = incategory_width / length(ms),
        add_category_first::Bool = true,
        strict_names_order::Bool = false,
    )

Gather all the information from the various models to make the groupedcoefplot.

"""
function get_merged_plotting_values(
    ms::StatisticalModel...;
    intercept::Bool = false,
    headers::Bool = false,
    useconfint::Bool = true,
    level::Union{Real, AbstractVector{<:Real}},
    term_width::Real = 1.0,
    incategory_width::Real = 0.5,
    offset::Real = term_width / 2,
    group_offset::Real = incategory_width / length(ms),
    strict_names_order::Bool = false,
)

    # Number of models
    M = length(ms)

    # use different confidence interval levels for the different models
    if isa(level, AbstractVector) && length(level) == M
        levels = collect(level)
    else
        levels = fill(only(level), M)
    end

    # For each model, get term names, coefs, errors as Vector of Vectors
    groups = Vector{ModelTree}(undef, M)
    names = Vector{Any}(undef, M)
    coefs = Vector{Any}(undef, M)
    errors = Vector{Any}(undef, M)
    title = ""
    for i in eachindex(levels, groups, names, coefs, errors)
        m = ms[i]
        level = levels[i]

        # Check the response variable is the same for all models
        response_i = responsename__(m)
        if title == ""
            title = response_i
        elseif response_i != title
            mess = ("only models with the same response name are allowed for groupedcoefplot. "*
                    "Got: $(response_i) != $(title)")
            @warn(mess)
            return ()
        end

        # get the names, coefs, errors for the current model
        g = create_forest_terms(m; intercept, headers, useconfint, level, add_category_first=false)
        # group the categorical terms
        groups[i] = get_modeltree(g)
        # get the names, coefs, errors for the current model as vectors
        names[i] = [t.name for t in g]
        coefs[i] = [t.coef for t in g]
        errors[i] = [t.error for t in g]
    end

    # make the ticks from merging the model terms
    tick_groups = merge_models(groups; strict_names_order)
    # make the tick values using spacing
    tick_yvals = cumsum(term_spacing(tick_groups; term_width, incategory_width, offset))
    # offset for each model
    shift = range(-group_offset * (M - 1) / 2, step = group_offset, length = M)

    # Find yvals of the corresponding term names for each model
    yvals = Vector{Any}(undef, M)
    for i in eachindex(yvals, groups, shift)
        s = shift[i]
        modeltree = groups[i]
        # find the index in the merged terms for the current term
        # and add a different offset for each model
        yvals_list = [tick_yvals[find_indices(mt, tick_groups; strict_names_order)] .+ s
                      for mt in modeltree]
        yvals[i] = vcat(yvals_list...)
    end

    # Process yticks names
    for modeltree in tick_groups
        if length(modeltree.variables) > 1
            # if category term, add the category name before the first element
            modeltree.variables[1] = "$(modeltree.term): $(modeltree.variables[1])"
        end
    end
    tick_names = vcat(getproperty.(tick_groups, :variables)...)

    return yvals, names, coefs, errors, title, tick_names, tick_yvals
end



"""
    format_error(coef::Real, error::Union{Real, Tuple{<:Real, <:Real}}; sigdigits::Integer=3)::String

Format a coefficient and error for showing values in the forest plot.
`error` can be a number for a symetric relative error or a tuple of lower/higher bound relative errors.
    
"""
function format_error(
    coef::Real,
    error::Union{Real, Tuple{<:Real, <:Real}};
    sigdigits::Integer = 3,
    )::String

    # Define formatting with significant digits
    format_number(num) = string(round(num; sigdigits))

    # Format coefficient
    str = format_number(coef)

    # Format confidence interval
    if isa(error, Real)
        err1 = coef - abs(error)
        err2 = coef + abs(error)
    else
        err1 = coef - error[1]
        err2 = coef + error[2]
    end
    str *= " ($(format_number(err1)), $(format_number(err2)))"
    return str
end

"""
    extrema_error(coef::Real, error::Union{Real, Tuple{<:Real, <:Real}})

Returns the extrema values of the confidence interval.
`error` can be a number for a symetric relative error or a tuple of lower/higher relative errors.
    
"""
function extrema_error(coef::Real, error::Union{Real, Tuple{<:Real, <:Real}})
    if isa(error, Real)
        ext1 = coef - abs(error)
        ext2 = coef + abs(error)
    else
        ext1 = min(coef, coef - error[1], coef + error[2])
        ext2 = max(coef, coef - error[1], coef + error[2])
    end
    return (ext1, ext2)
end

max_errors(coefs::AbstractVector{<:Real}, errors::AbstractVector) = maximum(last.(extrema_error.(coefs, errors)))
min_errors(coefs::AbstractVector{<:Real}, errors::AbstractVector) = minimum(first.(extrema_error.(coefs, errors)))

## Plot recipe

@userplot ForestPlot
recipetype(::Val{:forestplot}, args...) = ForestPlot(args)

@recipe function f(
    p::ForestPlot;
    models = 1:length(p.args[1]),
    orientation = :v,
    weights = nothing,
    offset = 0,
    reference = 0,
    showvalues = false,
    sigdigits = 3,
)
    horient = (orientation == :v)

    # Check arguments
    if length(p.args) == 2
        coefs = p.args[1]
        errors = p.args[2]
        yvals = 1:length(coefs)
    else
        mess = ("ForestPlot arguments should be a vector of coefficients and a vector of errors. " *
                "Got: $(typeof.(p.args))")
        throw(ArgumentError(mess))
    end

    # Parse tick names
    if isa(models, Tuple)
        yvals = models[1]
        names = models[2]
    else
        names = models
    end

    # Inverse the y-values to put the first above
    maxy = maximum(yvals)
    if horient
        yvals = maxy .+ offset .- yvals
    end

    # Limits
    yl = extrema(yvals) .+ (-offset, +offset)

    ## Plot recipe - everything above is just computation
    framestyle --> :grid
    grid := horient ? :x : :y
    if horient
        ylims := yl
        yticks := (yvals, names)
    else
        xlims := yl
        xticks := (yvals, names)
    end
    legend := false
    permute := (:x, :x)

    # coefs with error bars
    @series begin
        seriestype := :scatter
        if horient
            x := coefs
            y := yvals
            xerror := errors
        else
            x := yvals
            y := coefs
            yerror := errors
        end
        # marker size
        if !isnothing(weights) && length(weights) == length(coefs)
            markersize := weights
        end
        ()
    end

    # vertical line at reference value
    @series begin
        seriestype := horient ? :vline : :hline
        color := :black
        [reference]
    end

    # bottom/left horizontal line
    @series begin
        seriestype := horient ? :hline : :vline
        color := :black
        [0]
    end

    # show coefs and errors values
    if showvalues
        max_err = max_errors(coefs, errors)
        values_spacing = (max_err - min_errors(coefs, errors)) / 10
        xmax = max_err + values_spacing
        error_vals = [
            Plots.text(format_error(coefs[i], errors[i]; sigdigits); halign=:left)
            for i in eachindex(coefs, errors)
        ]
        @series begin
            seriestype := :scatter
            markerstrokecolor := Plots.RGBA(0,0,0,0.)  # make the points transparent
            seriescolor := Plots.RGBA(0,0,0,0.)        # do
            series_annotations := error_vals
            primary := false
            fill(xmax, length(yvals)), yvals
        end
    end

    ()
end
Plots.@deps forestplot scatter vline hline

@userplot CoefPlot
recipetype(::Val{:coefplot}, args...) = CoefPlot(args)

@recipe function f(
    p::CoefPlot;
    intercept = false,
    headers = false,
    orientation = :v,
    useconfint = true,
    level = 0.95,
    term_width = 1.0,
    incategory_width = 0.5,
    offset = term_width / 2,
    showvalues = false,
)
    if length(p.args) != 1 || !(all(check_type.(p.args)))
        mess = ("Coef Plot should be given one RegressionModel defined from a formula. "*
                "Got: $(typeof.(p.args))")
        throw(ArgumentError(mess))
    end
    m = p.args[1]
    if useconfint && !check_type_confint(m)
        mess = ("confint method is not defined for this RegressionModel, "*
                "use stderror instead: $(typeof(m))")
        @warn(mess)
        useconfint = false
    end

    # Get term names, coefs, error, yvals and title
    yvals, names, coefs, errors, title = get_plotting_values(
        m;
        intercept,
        headers,
        useconfint,
        level,
        term_width,
        incategory_width,
        offset,
    )

    horient = (orientation == :v)

    # Inverse the y-values to put intercept above
    if horient
        maxy = maximum(yvals)
        yvals = maxy .+ offset .- yvals
    end

    # Limits
    yl = extrema(yvals) .+ (-offset, +offset)

    ## Plot recipe - everything above is just computation
    framestyle --> :zerolines
    grid := horient ? :x : :y
    if horient
        ylims := yl
        yticks := (yvals, names)
    else
        xlims := yl
        xticks := (yvals, names)
    end
    title := title
    legend := false
    permute := (:x, :x)

    # coefs with error bars
    @series begin
        seriestype := :scatter
        if horient
            x := coefs
            y := yvals
            xerror := errors
        else
            x := yvals
            y := coefs
            yerror := errors
        end
        ()
    end

    # zero vertical line
    @series begin
        seriestype := horient ? :vline : :hline
        color := :black
        [0]
    end
    ()
end

@userplot GroupedCoefPlot
recipetype(::Val{:groupedcoefplot}, args...) = GroupedCoefPlot(args)

@recipe function f(
    p::GroupedCoefPlot;
    intercept = false,
    headers = false,
    orientation = :v,
    useconfint = true,
    level = 0.95,
    term_width = 1.0,
    incategory_width = 0.5,
    offset = term_width / 2,
    group_offset = incategory_width / length(p.args),
    strict_names_order = false,
)
    if !(all(check_type.(p.args)))
        mess = ("Grouped Coef Plot should be given only RegressionModel "*
                "defined with a formula as arguments.  Got: $(typeof.(p.args))")
        throw(ArgumentError(mess))
    end
    if useconfint && !all(check_type_confint.(p.args))
        mess = ("confint method is not defined for a RegressionModel argument, "*
                "use stderror instead: $(typeof.(m))")
        @warn(mess)
        useconfint = false
    end

    # Collect terms
    # `yvals` is now a Vector of Vector of Float64
    # where each model corresponds to one Vector of Float64
    yvals, names, coefs, errors, title, tick_names, tick_yvals = 
        get_merged_plotting_values(
            p.args...;
            level,
            intercept,
            headers,
            useconfint,
            term_width,
            incategory_width,
            offset,
            group_offset,
            strict_names_order,
        )

    # Process yticks names
    for t in allgroups
        if length(t.names) > 1
            # if category term, add the category name before the first element
            t.names[1] = "$(t.term): $(t.names[1])"
        end
    end
    allnames = vcat(getproperty.(allgroups, :names)...)

    horient = (orientation == :v)

    # Add group_offset to the offset
    M = length(p.args)
    offset = max(offset, group_offset * (M - 1) / 2)
    
    # Inverse the y-values to put intercept above
    if horient
        maxy = maximum(tick_yvals)
        tick_yvals = maxy .+ offset .- tick_yvals
        yvals = [maxy .+ offset .- iyvals for iyvals in yvals]
    end
    # Limits
    yl = extrema(tick_yvals) .+ (-offset, +offset)

    ## Plot recipe - everything above is just computation
    framestyle --> :zerolines
    legend --> :outerright
    grid := horient ? :x : :y
    if horient
        ylims := yl
        yticks := (tick_yvals, tick_names)
    else
        xlims := yl
        xticks := (tick_yvals, tick_names)
    end
    title := title
    permute := (:x, :x)

    # coefs with error bars
    for i in eachindex(names, yvals, coefs, errors)
        @series begin
            seriestype := :scatter
            if horient
                x := coefs[i]
                y := yvals[i]
                xerror := errors[i]
            else
                x := yvals[i]
                y := coefs[i]
                yerror := errors[i]
            end
            ()
        end
    end

    # No more label after this line
    label := ""

    # zero vertical line
    @series begin
        seriestype := horient ? :vline : :hline
        label := ""
        color := :black
        [0]
    end
    ()
end
