module RelaxationExample

using Plots, XLSX, DataFrames, Unitful
using GivEmExel, GivEmExel.SavingResults

using NonlinearSolve

using Unitful: ϵ0

export timerange, nl_lsq_fit, expmodel,  proc_data, saveplots, getplots #, anyfy_col!, prepare_xl, sep_unit # , proc_dataset
export procwhole, procsubset, combine2df, proc_n_save
export _proc_dataspan, _proc_data


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

function _proc_dataspan(df, t_start, t_stop)
    t_start = t_start |> ustrip
    t_stop = t_stop |> ustrip
    (; ts, ys) = timerange(df, t_start, t_stop);
    aᵢ = (ys[1])
    τᵢ = (t_stop - t_start) / 2
    t₀ᵢ = t_start
    (;sol, fit) = nl_lsq_fit(expmodel, [aᵢ, τᵢ], ts, ys, t₀ᵢ)
    a, τ = sol.u
    pl = plot(ts, [ys, fit]; label = ["experiment" "fit"])
    return (;a, τ, sol, fit, pl)
end


function _readdata(fl)
    df = DataFrame(XLSX.readtable(fl, DATATABLENAME; infer_eltypes=true))
    ts = df[!, :ts];
    ys = df[!, :ys];
    pl0 = plot(ts, ys)
    return (; df, pl0)
end

_calc_thickness(C, ϵ, area) = ϵ * ϵ0 * area / C |> u"µm"

function _finalize_plot!(pl, params)
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

function _proc_data(xlfile, datafile, paramsets; throwonerr=false)
    results = []
    results_df = []
    errors = []
    overview = (;)
    try
        (; df, pl0) = _readdata(xlfile)
        overview = (;pl0, subset=0)
        for (i, pm) in pairs(paramsets)
                (; area, Vunit, timeunit, Cunit, R, ϵ, no, plot_annotation, comment, t_start, t_stop) = pm
            try
                rslt = _proc_dataspan(df, t_start, t_stop)
                (;a, τ, sol, pl) = rslt
                _finalize_plot!(pl, pm)
                rs = (;subset=i, no, a, τ, sol, pl, plot_annotation)
                a *= Vunit
                τ *= timeunit
                c = (τ / R) 
                c = c |> Cunit 
                d = _calc_thickness(c, ϵ, area)
                rs_row = (;no, a, τ, c, d, R, ϵ, comment, t_start, t_stop)
                push!(results, rs)
                push!(results_df, rs_row)
            catch exceptn
                back_trace = stacktrace(catch_backtrace())
                push!(errors, (;row=i, comment, exceptn, back_trace))
                throwonerr && rethrow(exceptn)
            end
        end
        results_df=DataFrame(results_df)
    catch exceptn
        back_trace = stacktrace(catch_backtrace())
        push!(errors,(;row=-1, comment="error opening of processing data file", exceptn, back_trace))
        throwonerr && rethrow(exceptn)
    end
    return (; results, errors, results_df, overview)
end

function procwhole(xlfile, datafile, paramsets)
    (; df, pl0) = _readdata(xlfile)
    return (;pl0, df, subset=0)
end

function procsubset(i, pm_subset, overview, args...) 
    (; area, Vunit, timeunit, Cunit, R, ϵ, no, plot_annotation, comment, t_start, t_stop) = pm_subset
    df = overview.df
    rslt = _proc_dataspan(df, t_start, t_stop)
    (;a, τ, sol, pl) = rslt
    _finalize_plot!(pl, pm_subset)
    rs = (;subset=i, no, a, τ, sol, pl, plot_annotation)
    a *= Vunit
    τ *= timeunit
    c = (τ / R) 
    c = c |> Cunit 
    d = _calc_thickness(c, ϵ, area)
    df_row = (;no, a, τ, c, d, R, ϵ, comment, t_start, t_stop)
    return (;rs, df_row)
end

function proc_data(xlfile, datafile, paramsets, procwhole_fn, procsubset_fn; throwonerr=false)
    subsets_results = []
    errors = []
    overview = (;)
    try
        overview = procwhole_fn(xlfile, datafile, paramsets)
        for (i, pm_subset) in pairs(paramsets)
            try
                push!(subsets_results, procsubset_fn(i, pm_subset, overview, xlfile, datafile, paramsets))
            catch exceptn
                back_trace = stacktrace(catch_backtrace())
                comment = get(pm_subset, :comment, "")
                push!(errors, (;row=i, comment, exceptn, back_trace))
                throwonerr && rethrow(exceptn)
            end    
        end     
    catch exceptn
        back_trace = stacktrace(catch_backtrace())
        push!(errors,(;row=-1, comment="error opening of processing data file", exceptn, back_trace))
        throwonerr && rethrow(exceptn)
    end
    return (; overview, subsets_results, errors)
end

function combine2df(subsets_results)
    rows = []
    for sr in subsets_results
        r = get(sr, :df_row, nothing)
        isnothing(r) || push!(rows, r)
    end
    isempty(rows) && return nothing
    return DataFrame(rows)
end

function save_results(results, xlfile)
    (; overview, subsets_results, errors) = results
    (;fname, f_src, src_dir, rslt_dir, outf, errf) = out_paths(xlfile)
    subsets_df = combine2df(subsets_results)
    df2save = nothing
    if !isnothing(subsets_df)
        df2save = prepare_xl(subsets_df);
        XLSX.writetable(outf, "SubsetsRslt" => df2save; overwrite=true)
    end
    return (;df2save)
end

function proc_n_save(xlfile, datafile, paramsets, procwhole_fn, procsubset_fn; throwonerr=false)
    results = proc_data(xlfile, datafile, paramsets, procwhole_fn, procsubset_fn; throwonerr)
    (; overview, subsets_results, errors) = results
    (;df2save) = save_results(results, xlfile)

    return (; overview, subsets_results, errors, df2save) 
end


end # module RelaxationExample
