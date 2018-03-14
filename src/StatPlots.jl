
module StatPlots

using Reexport
@reexport using Plots
import Plots: _cycle
using Plots.PlotMeasures
using StatsBase
using Distributions
import IterableTables
import DataValues: DataValue
import TableTraits: column_types, column_names, getiterator, isiterabletable
import TableTraitsUtils: create_columns_from_iterabletable
import NamedTuples

import KernelDensity
@recipe f(k::KernelDensity.UnivariateKDE) = k.x, k.density
@recipe f(k::KernelDensity.BivariateKDE) = k.x, k.y, k.density.'

@shorthands cdensity

export @df

include("df.jl")
include("corrplot.jl")
include("cornerplot.jl")
include("distributions.jl")
include("boxplot.jl")
include("violin.jl")
include("hist.jl")
include("marginalhist.jl")
include("bar.jl")



end # module
