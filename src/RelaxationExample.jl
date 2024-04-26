module RelaxationExample

using GivEmExel
using Plots, XLSX, DataFrames, NonlinearSolve, Unitful

using Unitful: ϵ0

export timerange, nl_lsq_fit, expmodel, proc_dataspan, proc_data, anyfy_col!, prepare_xl, sep_unit # , proc_dataset

DATATABLENAME = "data"


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

function proc_data(xlfile, unusedfile, paramsets)
    (; df, pl0) = readdata(xlfile)
    results = []
    results_df = []
    for pm in paramsets
        (; area, Vunit, timeunit, Cunit, R, ϵ, no, plot_annotation, comment, t_start, t_stop) = pm
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
    end
    return (results, results_df=DataFrame(results_df ))
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

function anyfy_col!(df, cname) 
    df[!, cname] = Vector{Any}(df[!, cname])
    return nothing
end

function prepare_xl(df0)
    df = copy(df0)
    headers = String[]
    for nm in names(df)
        (;colheader, v) = sep_unit(df[!, nm])
        # (eltype(df[!, nm]) <: AbstractString) || 
        anyfy_col!(df, nm)
        push!(headers, colheader)
        colheader == "" || (df[!, nm] = v)
    end
    pushfirst!(df, headers)
    return df
end

function sep_unit(v)
    (eltype(v) <: Quantity) || return (;colheader = "", v)
    colheader = v |> eltype |> unit |> string
    v = v .|> ustrip |> Vector{Any}
    (;colheader, v)
end


end # module RelaxationExample
