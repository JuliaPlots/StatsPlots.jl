# StatPlots

[![Build Status](https://travis-ci.org/JuliaPlots/StatPlots.jl.svg?branch=master)](https://travis-ci.org/JuliaPlots/StatPlots.jl)


### Primary author: Thomas Breloff (@tbreloff)

This package contains many statistical recipes for concepts and types introduced in the JuliaStats organization, intended to be used with [Plots.jl](https://juliaplots.github.io):

- Types:
    - DataFrames
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

---

## marginalhist with DataFrames

```julia
using RDatasets
iris = dataset("datasets","iris")
marginalhist(iris, :PetalLength, :PetalWidth)
```

![](https://cloud.githubusercontent.com/assets/933338/16709018/81c4da34-45d2-11e6-9e08-bb557541e144.png)

---

## corrplot and cornerplot


```julia
M = randn(1000,4)
M[:,2] += 0.8sqrt(abs(M[:,1])) - 0.5M[:,3] + 5
M[:,3] -= 0.7M[:,1].^2 + 2
corrplot(M, label = ["x$i" for i=1:4])
```

![](https://cloud.githubusercontent.com/assets/933338/16030833/3c84e6bc-31c3-11e6-9a04-4cee531440a4.png)

```julia
cornerplot(M)
```

![](https://cloud.githubusercontent.com/assets/933338/17787905/2e161b7c-6559-11e6-937a-20209301905b.png)


```julia
cornerplot(M, compact=true)
```

![](https://cloud.githubusercontent.com/assets/933338/17787917/3af9b0e2-6559-11e6-8613-c177efb0b038.png)

---

## boxplot and violin

```julia
import RDatasets
singers = RDatasets.dataset("lattice","singer")
violin(singers,:VoicePart,:Height,marker=(0.2,:blue,stroke(0)))
boxplot!(singers,:VoicePart,:Height,marker=(0.3,:orange,stroke(2)))
```

![](https://juliaplots.github.io/examples/img/pyplot/pyplot_example_30.png)

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
