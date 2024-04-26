using RelaxationExample, GivEmExel

using Plots, XLSX, DataFrames
# plotlyjs()

f = "data/BrokenData.xlsx";

# f = "data/RelaxationExampleData.xlsx"
fl = joinpath(@__DIR__, "..", f);




(;df_setup, df_exp) = read_xl_paramtables(fl);
# (;nt) = merge_params(df_exp, df_setup, 1);

pst = exper_paramsets((;), df_exp, df_setup);
(;fname, f_src, src_dir, rslt_dir, outf, errf) = out_paths(fl)

(;results, errors, results_df) = proc_data(fl, nothing, pst);
df2save = prepare_xl(results_df);



XLSX.writetable(outf, "Results" => df2save; overwrite=true)

errored = write_errors(errf, errors)