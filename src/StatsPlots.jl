module StatsPlots

using Reexport
import RecipesBase: recipetype
@reexport using Plots
import Plots: _cycle
using Plots.PlotMeasures
using StatsBase
using Distributions
import IterableTables
import DataValues: DataValue
import TableTraits: getiterator, isiterabletable
import TableTraitsUtils: create_columns_from_iterabletable
using Widgets, Observables
import Observables: AbstractObservable, @map, observe
import Widgets: @nodeps
import DataStructures: OrderedDict
import Clustering: Hclust, nnodes

import KernelDensity
@recipe f(k::KernelDensity.UnivariateKDE) = k.x, k.density
@recipe f(k::KernelDensity.BivariateKDE) = k.x, k.y, permutedims(k.density)

@shorthands cdensity

export @df, dataviewer

include("df.jl")
include("interact.jl")
include("corrplot.jl")
include("cornerplot.jl")
include("distributions.jl")
include("boxplot.jl")
include("violin.jl")
include("hist.jl")
include("marginalhist.jl")
include("bar.jl")
include("dendrogram.jl")
include("andrews.jl")

end # module
