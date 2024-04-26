using RelaxationExample, GivEmExel

using Plots, XLSX, DataFrames
# plotlyjs()

fname = "data/RelaxationExampleData.xlsx"
fl = joinpath(@__DIR__, "..", fname)

(;df_setup, df_exp) = read_xl_paramtables(fl);
(;nt) = merge_params(df_exp, df_setup, 1);

pst = exper_paramsets((;), df_exp, df_setup);

results = proc_data(fl, nothing, pst);

# (;a, τ, sol, fit, pl0, pl1) = proc_dataset(fl);