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

The `DataFrames` support allows passing `DataFrame` columns as symbols. Operations on DataFrame column can be specified using quoted expressions, e.g.
```julia
using DataFrames
df = DataFrame(a = 1:10, b = 10*rand(10), c = 10 * rand(10))
plot(df, :a, [:b :c])
scatter(df, :a, :b, markersize = :(4 * log(:c + 0.1)))
```
If you find an operation not supported by DataFrames, please open an issue. An alternative approach to the `StatPlots` syntax is to use the [DataFramesMeta](https://github.com/JuliaStats/DataFramesMeta.jl) macro `@with`. Symbols not referring to DataFrame columns must be escaped by `^()` e.g.
```julia
using DataFramesMeta
@with(df, plot(:a, [:b :c], colour = ^([:red :blue])))
```
---

## marginalhist with DataFrames

```julia
using RDatasets
iris = dataset("datasets","iris")
marginalhist(iris, :PetalLength, :PetalWidth)
```

![](https://cloud.githubusercontent.com/assets/933338/19213780/a82e34a6-8d42-11e6-8846-80c9f4c48b9c.png)

---

## corrplot and cornerplot


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
violin(singers,:VoicePart,:Height,marker=(0.2,:blue,stroke(0)))
boxplot!(singers,:VoicePart,:Height,marker=(0.3,:orange,stroke(2)))
```

![](https://juliaplots.github.io/examples/img/pyplot/pyplot_example_30.png)

Asymmetric violin plots can be created using the `side` keyword (`:both` - default,`:right` or `:left`), e.g.:

```julia
singers_moscow = deepcopy(singers)
singers_moscow[:Height] = singers_moscow[:Height]+5
myPlot = violin(singers,:VoicePart,:Height, side=:right, marker=(0.2,:blue,stroke(0)), label="Scala")
violin!(singers_moscow,:VoicePart,:Height, side=:left, marker=(0.2,:red,stroke(0)), label="Moscow")
```

![](https://cloud.githubusercontent.com/assets/2077159/26156938/22ccf0d4-3b18-11e7-9f34-555005437e6c.png)

---

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


## groupapply for population analysis
There is a groupapply function that splits the data across a keyword argument "group", then applies "summarize" to get average and variability of a given analysis (density, cumulative, hazard rate and local regression are supported so far, but one can also add their own function). To get average and variability there are 3 ways:

- `compute_error = (:across, col_name)`, where the data is split according to column `col_name` before being summarized. `compute_error = :across` splits across all observations. Default summary is `(mean, sem)` but it can be changed with keyword `summarize` to any pair of functions.

- `compute_error = (:bootstrap, n_samples)`, where `n_samples` fake datasets distributed like the real dataset are generated and then summarized (nonparametric
<a href="https://en.wikipedia.org/wiki/Bootstrapping_(statistics)">bootstrapping</a>). `compute_error = :bootstrap` defaults to `compute_error = (:bootstrap, 1000)`. Default summary is `(mean, std)`. This method will work with any analysis but is computationally very expensive.

- `compute_error = :none`, where no error is computed or displayed and the analysis is carried out normally.

The local regression uses [Loess.jl](https://github.com/JuliaStats/Loess.jl) and the density plot uses [KernelDensity.jl](https://github.com/JuliaStats/KernelDensity.jl). In case of categorical x variable, these function are computed by splitting the data across the x variable and then computing the density/average per bin. The choice of continuous or discrete axis can be forced via `axis_type = :continuous` or `axis_type = :discrete`

Example use:

```julia
using DataFrames
import RDatasets
using StatPlots
gr()
school = RDatasets.dataset("mlmRev","Hsb82");
grp_error = groupapply(:cumulative, school, :MAch; compute_error = (:across,:School), group = :Sx)
plot(grp_error, line = :path, legend = :topleft)
```
<img width="494" alt="screenshot 2016-12-19 12 28 27" src="https://user-images.githubusercontent.com/6333339/29280675-1a8df192-8114-11e7-878e-754ecdd9184d.png">

Keywords for loess or kerneldensity can be given to groupapply:

```julia
grp_error = groupapply(:density, school, :CSES; bandwidth = 0.2, compute_error = (:bootstrap,500), group = :Minrty)
plot(grp_error, line = :path)
```

<img width="487" alt="screenshot 2017-01-10 18 36 48" src="https://user-images.githubusercontent.com/6333339/29280692-2bc1f97c-8114-11e7-932e-a86156d36cf5.png">


The bar plot

```julia
pool!(school, :Sx)
grp_error = groupapply(school, :Sx, :MAch; compute_error = :across, group = :Minrty)
plot(grp_error, line = :bar)
```
<img width="489" alt="screenshot 2017-01-10 18 20 51" src="https://user-images.githubusercontent.com/6333339/29280710-3998b310-8114-11e7-9a24-a93d5727cc52.png">
