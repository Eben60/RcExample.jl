module RelaxationExample

using GivEmExel
using Plots, XLSX, DataFrames, NonlinearSolve, Unitful

using Unitful: ϵ0

export timerange, nl_lsq_fit, expmodel, proc_dataspan, proc_data #, anyfy_col!, prepare_xl, sep_unit # , proc_dataset

DATATABLENAME = "data"


function timerange(df0, t1, t2)
    df = subset(df0, :ts => x -> (x.>t1).&(x.<t2))
    ts = Float64.(df[!, :ts]);
    ys = Float64.(df[!, :ys]);
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
    t_start = t_start |> ustrip
    t_stop = t_stop |> ustrip
    (; ts, ys) = timerange(df, t_start, t_stop);
    aᵢ = (ys[1])
    τᵢ = (t_stop - t_start) / 2
    t₀ᵢ = t_start
    (;sol, fit) = nl_lsq_fit(expmodel, [aᵢ, τᵢ], ts, ys, t₀ᵢ)
    a, τ = sol.u
    pl1 = plot(ts, [ys, fit]; label = ["experiment" "fit"])
    return (;a, τ, sol, fit, pl1)
end


function readdata(fl)
    df = DataFrame(XLSX.readtable(fl, DATATABLENAME; infer_eltypes=true))
    ts = df[!, :ts];
    ys = df[!, :ys];
    pl0 = plot(ts, ys)
    return (; df, pl0)
end

function proc_data(xlfile, unusedfile, paramsets; throwonerr=false)
    results = []
    results_df = []
    errors = []
    try
        (; df, pl0) = readdata(xlfile)
        for (i, pm) in pairs(paramsets)
                (; area, Vunit, timeunit, Cunit, R, ϵ, no, plot_annotation, comment, t_start, t_stop) = pm
            try
                rslt = proc_dataspan(df, t_start, t_stop)
                (;a, τ, sol, pl1) = rslt
                finalize_plot!(pl1, pm)
                rs = (;a, τ, sol, pl1)
                a *= Vunit
                τ *= timeunit
                c = (τ / R) 
                c = c |> Cunit 
                d = calc_thickness(c, ϵ, area)
                rs_row = (;no, a, τ, c, d, R, ϵ, comment, t_start, t_stop)
                push!(results, rs)
                push!(results_df, rs_row)
            catch exceptn
                push!(errors, (;row=i, comment, exceptn))
                throwonerr && rethrow(exceptn)
            end
        end
        results_df=DataFrame(results_df)
    catch exceptn
        push!(errors,(;row=-1, comment="error opening of processing data file", exceptn))
        throwonerr && rethrow(exceptn)
    end
    return (; results, errors, results_df)
end

calc_thickness(C, ϵ, area) = ϵ * ϵ0 * area / C |> u"µm"

function finalize_plot!(pl, params)
    (; Vunit, timeunit, plot_annotation) = params
    sz = (800, 600)
    xunit = timeunit |> string
    yunit = Vunit |> string
    pl = plot!(pl; 
        size=sz, 
        xlabel = "time [$xunit]", 
        ylabel = "Voltage [$yunit]", 
        title = "$plot_annotation",
        )
    return pl
end

end # module RelaxationExample
