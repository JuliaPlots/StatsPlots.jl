
# StatsPlots.jl NEWS
## 0.10
- Rename package from StatPlots to StatsPlots


## 0.7 current version

### 0.7.3

- fixed out of bound error with `violin` and `boxplot`
- fixed title location in `corrplot`
- better handling of `NaN` and `Inf`
- recipe for `hclust` dendrogram (clustering visualization)
- `dataviewer` recipe for interactive GUIs

### 0.7.2

- fix stack overflow with `@df` and `begin ... end` blocks
- avoid recomputing data unnecessarily in `@df`

### 0.7.1

- remove Loess dependency
- fix hygien macro issue in `@df`
- add curly bracket syntax for automatic naming of groups
- add `cols()` to select all columns

### 0.7.0
- remove DataFrames dependency
- improve tick handling in correlation plots
- add support for discrete distributions
- add automatic legend with `@df`
- allow passing columns of a data table programmatically with `cols`

### 0.6.0
- deprecate the `plot(df, :x, :y)` syntax
- complete the removal of groupederror
- remove shadederror
- suppress axis labels in marginalhist

### 0.5.1
- remove groupederror, as that is now in it's own package
- add `qqnorm` and `qqplot`
- fix 2d density plots

### 0.5.0
- major reconfiguring of the support for tables:
    - change the syntax to `@df mydataframe plot(:a, :b)`
    - allows using DataFrames automatically in user recipes
    - support for all iterable tables, including DataFrame, DataTable, IndexedTable, IterableTable and DataStreams.Source
- better interface to `groupedbar`
- added equal-area histograms
- added the `:wand` binning option for 1-dimensional histograms

### 0.4.2
- improvements to the groupapply function

### 0.4.1
patch release
- reexport Plots

### 0.4.0
- Fix 0.6 deprecations
- support for `_cycle`

### 0.3.0
- added expressions with DataFrame symbols
- added `groupapply` method for population analysis
- updated boxplots to turn off outlier points and improves whiskers
