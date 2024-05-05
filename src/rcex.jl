using RcExample
using GivEmExel, GivEmExel.SavingResults #, GivEmExel.InternalArgParse

# Macni2020M1 RcExample.jl % julia --project=. src/prompt2.jl -e --plotformat none

fn(; kwargs...) = proc_n_save(procwhole, procsubset; kwargs...)

fi = full_interact(pp0, pps, fn; getexel=true, getdata=(; dialogtype = :none))

