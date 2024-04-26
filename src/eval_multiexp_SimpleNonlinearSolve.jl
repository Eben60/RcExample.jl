using RelaxationExample

using Plots, XLSX, DataFrames
# plotlyjs()

fname = "data/RelaxationExampleData.xlsx"
fl = joinpath(@__DIR__, "..", fname)

@assert isfile(fl)
datatablename = "data"
df = DataFrame(XLSX.readtable(fl, datatablename; infer_eltypes=true))

ts = df[!, :ts];
ys = df[!, :ys];

pl0 = plot(ts, ys)
display(pl0)




(; ts, ys) = timerange(df, 6, 12);



aᵢ, τᵢ, t₀ᵢ = 1.0, 2.0, 6.0



(;sol, fit) = nl_lsq_fit(expmodel, [aᵢ, τᵢ], ts, ys, t₀ᵢ)

a, τ = sol.u

pl1 = plot(ts, [ys, fit])
display(pl1)