
module StatPlots

using Reexport
@reexport using Plots
import Plots: _cycle
using StatsBase
using Distributions
using DataFrames
using IterableTables
import DataValues: DataValue
import TableTraits: column_types, column_names

import KernelDensity
import Loess
@recipe f(k::KernelDensity.UnivariateKDE) = k.x, k.density
@recipe f(k::KernelDensity.BivariateKDE) = k.x, k.y, k.density

@shorthands cdensity

export groupapply
export get_groupederror
export @df

include("df.jl")
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
