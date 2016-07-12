
__precompile__()

module StatPlots

using Reexport
@reexport using Plots
using StatsBase
using Distributions
using DataFrames

include("dataframes.jl")
include("corrplot.jl")
include("cornerplot.jl")
include("distributions.jl")
include("boxplot.jl")
include("violin.jl")
include("hist.jl")
include("marginalhist.jl")

end # module
