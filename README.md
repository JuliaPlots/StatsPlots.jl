# StatPlots

[![Build Status](https://travis-ci.org/JuliaPlots/StatPlots.jl.svg?branch=master)](https://travis-ci.org/JuliaPlots/StatPlots.jl)


### Primary author: Thomas Breloff (@tbreloff)

This package contains many statistical recipes for concepts and types introduced in the JuliaStats organization, intended to be used with [Plots.jl](https://juliaplots.github.io):

- Types:
    - DataFrames (for DataTables support, checkout the `DataTables` branch)
    - Distributions
- Recipes:
    - histogram/histogram2d
    - boxplot
    - violin
    - marginalhist
    - corrplot/cornerplot

Initialize:

```julia
#Pkg.clone("git@github.com:JuliaPlots/StatPlots.jl.git")
using StatPlots
gr(size=(400,300))
```

Table-like data structures, including `DataFrames`, `IndexedTables`, `DataStreams`, etc... (see [here](https://github.com/davidanthoff/IterableTables.jl) for an exhaustive list), are supported thanks to the macro `@df` which allows passing columns as symbols. Those columns can then be manipulated inside the `plot` call, like normal `Arrays`:
```julia
using DataFrames, IndexedTables
df = DataFrame(a = 1:10, b = 10*rand(10), c = 10 * rand(10))
@df df plot(:a, [:b :c], colour = [:red :blue])
@df df scatter(:a, :b, markersize = 4 * log.(:c + 0.1))
t = table(1:10, rand(10), names = [:a, :b]) # IndexedTable
@df t scatter(2 * :b)
```

Inside a `@df` macro call, the `cols` utility function can be used to refer to a range of columns:

```julia
@df df plot(:a, cols(2:3), colour = [:red :blue])
```

or to refer to a column whose symbol is represented by a variable:

```julia
s = :b
@df df plot(:a, cols(s))
```

In case of ambiguity, symbols not referring to `DataFrame` columns must be escaped by `^()`:
```julia
df[:red] = rand(10)
@df df plot(:a, [:b :c], colour = ^([:red :blue]))
```

The `@df` macro plays nicely with the new syntax of the [Query.jl](https://github.com/davidanthoff/Query.jl) data manipulation package (v0.8 and above), in that a plot command can be added at the end of a query pipeline, without having to explicitly collect the outcome of the query first:

```julia
using Query, StatPlots
df |>
    @filter(_.a > 5) |>
    @map({_.b, d = _.c-10}) |>
    @df scatter(:b, :d)
```

The `@df` syntax is also compatible with Plots grouping machinery:

```julia
using RDatasets
school = RDatasets.dataset("mlmRev","Hsb82")
@df school density(:MAch, group = :Sx)
```

To group by more than one column, use a tuple of symbols:

```julia
@df school density(:MAch, group = (:Sx, :Sector), legend = :topleft)
```

![grouped](https://user-images.githubusercontent.com/6333339/35101563-eacf9be4-fc57-11e7-88d3-db5bb47b08ac.png)

---

The old syntax, passing the `DataFrame` as the first argument to the `plot` call is no longer supported.

---

## marginalhist with DataFrames

```julia
using RDatasets
iris = dataset("datasets","iris")
@df iris marginalhist(:PetalLength, :PetalWidth)
```

![marginalhist](https://user-images.githubusercontent.com/6333339/29869938-fbe08d02-8d7c-11e7-9409-ca47ee3aaf35.png)

---

## corrplot and cornerplot

```julia
@df iris corrplot([:SepalLength :SepalWidth :PetalLength :PetalWidth], grid = false)
```
or also:
```julia
@df iris corrplot(cols(1:4), grid = false)
```

![corrplot](https://user-images.githubusercontent.com/6333339/29870023-7b07b010-8d7d-11e7-901c-3ef9a6af78bb.png)


A correlation plot may also be produced from a matrix:

```julia
M = randn(1000,4)
M[:,2] += 0.8sqrt.(abs.(M[:,1])) - 0.5M[:,3] + 5
M[:,3] -= 0.7M[:,1].^2 + 2
corrplot(M, label = ["x$i" for i=1:4])
```

![](https://cloud.githubusercontent.com/assets/933338/19213784/c5e09fde-8d42-11e6-8bda-b339ebfa8bd6.png)

```julia
cornerplot(M)
```

![](https://cloud.githubusercontent.com/assets/933338/19213788/de307db6-8d42-11e6-917a-5de3ff6a8666.png)


```julia
cornerplot(M, compact=true)
```

![](https://cloud.githubusercontent.com/assets/933338/19213790/ec530b52-8d42-11e6-9139-e674558c65e9.png)

---

## boxplot and violin

```julia
import RDatasets
singers = RDatasets.dataset("lattice","singer")
@df singers violin(:VoicePart,:Height,marker=(0.2,:blue,stroke(0)))
@df singers boxplot!(:VoicePart,:Height,marker=(0.3,:orange,stroke(2)))
```

![violin](https://user-images.githubusercontent.com/6333339/29870077-b4242e32-8d7d-11e7-9b18-40a57360936d.png)

Asymmetric violin plots can be created using the `side` keyword (`:both` - default,`:right` or `:left`), e.g.:

```julia
singers_moscow = deepcopy(singers)
singers_moscow[:Height] = singers_moscow[:Height]+5
@df singers violin(:VoicePart,:Height, side=:right, marker=(0.2,:blue,stroke(0)), label="Scala")
@df singers_moscow violin!(:VoicePart,:Height, side=:left, marker=(0.2,:red,stroke(0)), label="Moscow")
```

![2violin](https://user-images.githubusercontent.com/6333339/29870110-d90ed468-8d7d-11e7-8ebb-008323dff8b8.png)

---

## Equal-area histograms

The ea-histogram is an alternative histogram implementation, where every 'box' in
the histogram contains the same number of sample points and all boxes have the same
area. Areas with a higher density of points thus get higher boxes. This type of
histogram shows spikes well, but may oversmooth in the tails. The y axis is not
intuitively interpretable.

```julia
a = [randn(100); randn(100)+3; randn(100)/2+3]
ea_histogram(a, bins = :scott, fillalpha = 0.4)
```

<img width="487" alt="equal area histogram"
src ="https://user-images.githubusercontent.com/8429802/29754490-8d1b01f6-8b86-11e7-9f86-e1063a88dfd8.png">

---

## Distributions

```julia
using Distributions
plot(Normal(3,5), fill=(0, .5,:orange))
```

![](https://cloud.githubusercontent.com/assets/933338/16718702/561510f6-46f0-11e6-834a-3cf17a5b77d6.png)

```julia
dist = Gamma(2)
scatter(dist, leg=false)
bar!(dist, func=cdf, alpha=0.3)
```

![](https://cloud.githubusercontent.com/assets/933338/16718720/729b6fea-46f0-11e6-9bff-fdf2541ce305.png)

### Quantile-Quantile plots

The `qqplot` function compares the quantiles of two distributions, and accepts either a vector of sample values or a `Distribution`. The `qqnorm` is a shorthand for comparing a distribution to the normal distribution. If the distributions are similar the points will be on a straight line.

```julia
x = rand(Normal(), 100)
y = rand(Cauchy(), 100)

plot(
 qqplot(x, y, qqline = :fit), # qqplot of two samples, show a fitted regression line
 qqplot(Cauchy, y),           # compare with a Cauchy distribution fitted to y; pass an instance (e.g. Normal(0,1)) to compare with a specific distribution
 qqnorm(x, qqline = :R)       # the :R default line passes through the 1st and 3rd quartiles of the distribution
)
```
<img width="1185" alt="skaermbillede 2017-09-28 kl 22 46 28" src="https://user-images.githubusercontent.com/8429802/30989741-0c4f9dac-a49f-11e7-98ff-028192a8d5b1.png">

## Grouped Bar plots

```julia
groupedbar(rand(10,3), bar_position = :stack, bar_width=0.7)
```

![tmp](https://cloud.githubusercontent.com/assets/933338/18962081/58a2a5e0-863d-11e6-8638-94f88ecc544d.png)

This is the default:

```julia
groupedbar(rand(10,3), bar_position = :dodge, bar_width=0.7)
```

![tmp](https://cloud.githubusercontent.com/assets/933338/18962092/673f6c78-863d-11e6-9ee9-8ca104e5d2a3.png)

The `group` syntax is also possible in combination with `groupedbar`:

```julia
groupedbar([1, 2, 1, 2, 1, 2], rand(6), group = [1, 1, 2, 2, 3, 3])
```

## GroupedErrors.jl for population analysis

Population analysis on a table-like data structures can be done using the highly recommended [GroupedErrors](https://github.com/piever/GroupedErrors.jl) package.

This external package, in combination with StatPlots, greatly simplifies the creation of two types of plots:

### 1. Subject by subject plot (generally a scatter plot)

Some simple summary statistics are computed for each experimental subject (mean is default but any scalar valued function would do) and then plotted against some other summary statistics, potentially splitting by some categorical experimental variable.

### 2. Population plot (generally a ribbon plot in continuous case, or bar plot in discrete case)

Some statistical analysis is computed at the single subject level (for example the density/hazard/cumulative of some variable, or the expected value of a variable given another) and the analysis is summarized across subjects (taking for example mean and s.e.m), potentially splitting by some categorical experimental variable.


For more information please refer to the [README](https://github.com/piever/GroupedErrors.jl/blob/master/README.md).

A GUI based on QML and the GR Plots.jl backend to simplify the use of StatPlots.jl and GroupedErrors.jl even further can be found [here](https://github.com/piever/PlugAndPlot.jl) (usable but still in alpha stage).
