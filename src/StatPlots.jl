
module StatPlots

using Reexport
using Plots
import Plots: _cycle
using StatsBase
using Distributions
using DataFrames

import KernelDensity
import Loess
@recipe f(k::KernelDensity.UnivariateKDE) = k.x, k.density
@recipe f(k::KernelDensity.BivariateKDE) = k.x, k.y, k.density

@shorthands cdensity

export groupapply
export get_groupederror

include("dataframes.jl")
include("corrplot.jl")
include("cornerplot.jl")
include("distributions.jl")
include("boxplot.jl")
include("violin.jl")
include("hist.jl")
include("marginalhist.jl")
include("bar.jl")
include("shadederror.jl")
include("groupederror.jl")



end # module
