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
# display(pl0)

t_start, t_stop = 6.0, 12.0

