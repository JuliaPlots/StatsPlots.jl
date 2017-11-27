
# deprecate the old DataFrame syntax
@recipe f(df::AbstractDataFrame, args...) = error("""
The `plot(df, args...)` syntax for plotting DataFrames has been deprecated.
Instead use the @df macro, e.g.
    mydata = DataFrame(a = 1:10, b = 10*rand(10), c = 10 * rand(10))
    @df mydata plot(:a, [:b :c], colour = [:red :blue])
"""
)
