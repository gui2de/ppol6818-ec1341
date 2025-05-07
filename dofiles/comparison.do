do "$wd\stata_3\01_data\sim_summary_emc.dt"

gen ci_width_mean = ci_high_mean - ci_low_mean

list sample_n beta_mean stderr_mean ci_width_mean beta_sd stderr_sd, sepby(sample_n)

gen type = "fixed"
rename sample_n sample_size

* Save as base temporary file
tempfile combined
save `combined'

* Load superpopulation summary
use "stata_3\01_data\siminf_summary_emc.dta", clear
gen type = "superpop"

* Append fixed population summary
append using `combined'

* Save combined dataset
save "\stata_3\01_data\combined_summary_emc.dta", replace

list type sample_size beta_mean stderr_mean ciwidth_mean, sepby(type sample_size)

twoway (line stderr_mean sample_size if type=="fixed", sort) ///
       (line stderr_mean sample_size if type=="superpop", sort lpattern(dash)), ///
       title("SEM vs. Sample Size: Fixed vs. Superpop") ///
       legend(label(1 "Fixed Pop") label(2 "Superpop")) ///
       xlabel(, labsize(vsmall)) ///
       ytitle("Standard Error of Beta") ///
       xtitle("Sample Size")

graph export "01_data/fig_comparison_sem.png", replace

export excel using "01_data/comparison_summary.xlsx", firstrow(variables) replace
