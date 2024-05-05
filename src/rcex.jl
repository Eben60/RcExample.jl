using RcExample
using GivEmExel, GivEmExel.SavingResults #, GivEmExel.InternalArgParse

# using RelaxationExample: pp0, pps

# fname = splitpath(@__FILE__)[end]

# include("prompt-init.jl")


# Macni2020M1 RelaxationExample.jl % julia --project=. src/prompt2.jl -e --plotformat none

# pps = (;gen_options, spec_options, exelfile_prompt, next_file)

fn(; kwargs...) = proc_n_save(procwhole, procsubset; kwargs...)

fi = full_interact(pp0, pps, fn; getexel=true, getdata=(; dialogtype = :none))

