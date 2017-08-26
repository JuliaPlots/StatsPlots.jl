
# ---------------------------------------------------------------------------
# density

@recipe function f(::Type{Val{:density}}, x, y, z; trim=false)
    newx, newy = violin_coords(y, trim=trim)
    if Plots.isvertical(d)
        newx, newy = newy, newx
    end
    x := newx
    y := newy
    seriestype := :path
    ()
end
Plots.@deps density path


# ---------------------------------------------------------------------------
# cumulative density

@recipe function f(::Type{Val{:cdensity}}, x, y, z; trim=false,
                   npoints = 200)
    newx, newy = violin_coords(y, trim=trim)

    if Plots.isvertical(d)
        newx, newy = newy, newx
    end

    newy = [sum(newy[1:i]) for i = 1:length(newy)] / sum(newy)

    x := newx
    y := newy
    seriestype := :path
    ()
end
Plots.@deps cdensity path



function linbin(X, gpoints; truncate = true)
    n, M = length(x), length(gpoints)

    a, b = gpoints[1], gpoints[M]
    gcnts = zeros(M)
    delta = (b-a)/(M-1)

    for i in 1:n
        lxi = ((X[i]-a)/delta) + 1
        li = floor(Int, lxi)
        rem = lxi - li

        if 1 <= li < M
            gcnts[li] += 1-rem
            gcnts[li+1] += rem
        end

        if !truncate
            if lt < 1
                gcnts[1] += 1
            end

            if li >= M
                gcnts[M] += 1
            end
        end
    end
    gcnts
end



function wand_bins(x, scalest = :minim, level = 2, gridsize = 401, range_x = extrema(x), truncate = true)

    level > 5 && error("Level should be between 0 and 5")
    n = length(x)
    minx = range_x[1]
    maxx = range_x[2]
    gpoints = linspace(minx, maxx, gridsize)
    gcounts = linbin(x, gpoints, truncate)

    scalest = if scalest == :stdev
        sqrt(var(x))
    elseif scalest == :iqr
        (quantile(x, 3//4) - quantile(x, 1//4))/1.349
    elseif scalest == :minim
        min((quantile(x, 3//4) - quantile(x, 1//4))/1.349, sqrt(var(x))
    else
        error("scalest must be one of :stdev, :iqr or :minim (default)")
    end

    scalest == 0 && error("scale estimate is zero for input data")
    sx = (x .- mean(x))./scalest
    sa = (minx - mean(x))/scalest
    sb = (maxx - mean(x))/scalest

    gpoints = linspace(sa, sb, gridsize)
    gcounts = linbin(sx, gpoints, truncate)

# made it to here with porting

    hpi <- if (level == 0L)
        (24 * sqrt(pi)/n)^(1/3)
    else if (level == 1L) {
        alpha <- (2/(3 * n))^(1/5) * sqrt(2)
        psi2hat <- bkfe(gcounts, 2L, alpha, range.x = c(sa, sb),
            binned = TRUE)
        (6/(-psi2hat * n))^(1/3)
    }
    else if (level == 2L) {
        alpha <- ((2/(5 * n))^(1/7)) * sqrt(2)
        psi4hat <- bkfe(gcounts, 4L, alpha, range.x = c(sa, sb),
            binned = TRUE)
        alpha <- (sqrt(2/pi)/(psi4hat * n))^(1/5)
        psi2hat <- bkfe(gcounts, 2L, alpha, range.x = c(sa, sb),
            binned = TRUE)
        (6/(-psi2hat * n))^(1/3)
    }
    else if (level == 3L) {
        alpha <- ((2/(7 * n))^(1/9)) * sqrt(2)
        psi6hat <- bkfe(gcounts, 6L, alpha, range.x = c(sa, sb),
            binned = TRUE)
        alpha <- (-3 * sqrt(2/pi)/(psi6hat * n))^(1/7)
        psi4hat <- bkfe(gcounts, 4L, alpha, range.x = c(sa, sb),
            binned = TRUE)
        alpha <- (sqrt(2/pi)/(psi4hat * n))^(1/5)
        psi2hat <- bkfe(gcounts, 2L, alpha, range.x = c(sa, sb),
            binned = TRUE)
        (6/(-psi2hat * n))^(1/3)
    }
    else if (level == 4L) {
        alpha <- ((2/(9 * n))^(1/11)) * sqrt(2)
        psi8hat <- bkfe(gcounts, 8L, alpha, range.x = c(sa, sb),
            binned = TRUE)
        alpha <- (15 * sqrt(2/pi)/(psi8hat * n))^(1/9)
        psi6hat <- bkfe(gcounts, 6L, alpha, range.x = c(sa, sb),
            binned = TRUE)
        alpha <- (-3 * sqrt(2/pi)/(psi6hat * n))^(1/7)
        psi4hat <- bkfe(gcounts, 4L, alpha, range.x = c(sa, sb),
            binned = TRUE)
        alpha <- (sqrt(2/pi)/(psi4hat * n))^(1/5)
        psi2hat <- bkfe(gcounts, 2L, alpha, range.x = c(sa, sb),
            binned = TRUE)
        (6/(-psi2hat * n))^(1/3)
    }
    else if (level == 5L) {
        alpha <- ((2/(11 * n))^(1/13)) * sqrt(2)
        psi10hat <- bkfe(gcounts, 10L, alpha, range.x = c(sa,
            sb), binned = TRUE)
        alpha <- (-105 * sqrt(2/pi)/(psi10hat * n))^(1/11)
        psi8hat <- bkfe(gcounts, 8L, alpha, range.x = c(sa, sb),
            binned = TRUE)
        alpha <- (15 * sqrt(2/pi)/(psi8hat * n))^(1/9)
        psi6hat <- bkfe(gcounts, 6L, alpha, range.x = c(sa, sb),
            binned = TRUE)
        alpha <- (-3 * sqrt(2/pi)/(psi6hat * n))^(1/7)
        psi4hat <- bkfe(gcounts, 4L, alpha, range.x = c(sa, sb),
            binned = TRUE)
        alpha <- (sqrt(2/pi)/(psi4hat * n))^(1/5)
        psi2hat <- bkfe(gcounts, 2L, alpha, range.x = c(sa, sb),
            binned = TRUE)
        (6/(-psi2hat * n))^(1/3)
    }
    scalest * hpi
end
