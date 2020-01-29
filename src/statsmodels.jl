# Note both predict and RegressionModel are defined in StatsBase
@recipe function f(mod::RegressionModel)
    newx = [ones(200) range(extrema(mod.model.pp.X[:,2])..., length = 200)]
    newy, l, u = predict(mod, newx, interval = :confidence)
    ribbon := (vec(u)-newy, newy-vec(l))
    label --> "model"
    newx[:,2], newy
end
