using PrecompileTools: @setup_workload, @compile_workload 
using GivEmExel: s2unit

# @compile_workload begin
#     s2unit("s/cm^2")
# end


@setup_workload begin
    testfiles = ["data/RelaxationExampleData.xlsx",
        "data/MissingData.xlsx",
        "data/BrokenData.xlsx",
        ]
        cliargs = (;plotformat="none", throwonerr=false)
    @compile_workload begin
        # println("successfully converted $(s2unit("J/m^2"))")
        for f in testfiles
            fl = joinpath(@__DIR__, "..", f);
            (;df_setup, df_exp) = read_xl_paramtables(fl; paramtables=(;setup="params_setup", exper="params_experiment"));
            paramsets = exper_paramsets(cliargs, df_exp, df_setup)
            rslt = proc_n_save(procwhole, procsubset; paramsets, xlfile=fl);
        end
    end
end