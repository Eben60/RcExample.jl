module RelaxationExample

using GivEmExel
using Plots, XLSX, DataFrames, NonlinearSolve

export timerange, nl_lsq_fit, expmodel, proc_dataspan

function timerange(df0, t1, t2)
    df = subset(df0, :ts => x -> (x.>t1).&(x.<t2))
    ts = df[!, :ts];
    ys = df[!, :ys];
    return (; ts, ys)
end

function nl_lsq_fit(model, u0, xdata, ydata, p)
    data = (xdata, ydata, p)

    function lossfn!(du, u, data)
        (xs, ys, p) = data   
        du .= model.(xs, Ref(u), Ref(p)) .- ys
        return nothing
    end

    prob = NonlinearLeastSquaresProblem(
        NonlinearFunction(lossfn!, resid_prototype = similar(ydata)), u0, data)
    sol = solve(prob)
    u = sol.u
    fit = model.(xdata, Ref(u), Ref(p))
    return (;sol, fit)
end

function expmodel(x, u, t₀=0)
    # y0 = u[1]
    a = u[1]
    τ = u[2]
    return a * exp(-(x-t₀)/τ) # + y0 
end

function proc_dataspan(df, t_start, t_stop)
    (; ts, ys) = timerange(df, t_start, t_stop);
    aᵢ = (ys[1])
    τᵢ = (t_stop - t_start) / 2
    t₀ᵢ = t_start
    (;sol, fit) = nl_lsq_fit(expmodel, [aᵢ, τᵢ], ts, ys, t₀ᵢ)
    a, τ = sol.u
    pl1 = plot(ts, [ys, fit])
    return (;a, τ, sol, fit, pl1)
end


end # module RelaxationExample
