# using Unitful, DataFrames, XLSX, Plots
using GivEmExel.SavingResults
using GivEmExel
using RelaxationExample

f = "data/MissingData.xlsx";

f = "data/RelaxationExampleData.xlsx"
# f = "data/BrokenData.xlsx";
fl = joinpath(@__DIR__, "..", f);

# rslt = proc_n_save(fl, nothing, procwhole, procsubset; [paramsets=(;plotformat="svg", throwonerr=true)]);
# rslt = proc_n_save(procwhole, procsubset; xlfile=fl, paramsets=[(;plotformat="svg", throwonerr=true)]);

(;df_setup, df_exp) = read_xl_paramtables(fl; paramtables=(;setup="params_setup", exper="params_experiment"));
cliargs = (;)
cliargs = (;plotformat="none", throwonerr=false)
paramsets = exper_paramsets(cliargs, df_exp, df_setup)

rslt = proc_n_save(procwhole, procsubset; paramsets, xlfile=fl);
; #, paramsets=[(;plotformat="svg", throwonerr=true)]);