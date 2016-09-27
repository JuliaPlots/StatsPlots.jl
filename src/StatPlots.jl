
__precompile__()

module StatPlots

using Reexport
@reexport using Plots
using StatsBase
using Distributions
using DataFrames

import KernelDensity
@recipe f(k::KernelDensity.UnivariateKDE) = k.x, k.density
@recipe f(k::KernelDensity.BivariateKDE) = k.x, k.y, k.density

@shorthands cdensity

include("dataframes.jl")
include("corrplot.jl")
include("cornerplot.jl")
include("distributions.jl")
include("boxplot.jl")
include("violin.jl")
include("hist.jl")
include("marginalhist.jl")

end # module
