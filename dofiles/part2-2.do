* siminf_summary_emc.do
* Author: Emmanuel Carrasco Hernandez
* Purpose: Analyze results from infinite superpopulation simulations (Part 2.3)

* -----------------------------------------------------
* Set working directory and load dataset
* -----------------------------------------------------
global wd "C:\Users\52777\Documents\Georgetown\Spring 2025\ppol_6818\Week 8\stata_3"
cd "$wd"

clear all
use "01_data/siminf_emc.dta", clear

* -----------------------------------------------------
* Create summary table: mean + sd for beta, stderr, and CI width
* -----------------------------------------------------
gen ci_width = ci_high - ci_low
gen beta_copy = beta
gen stderr_copy = stderr
gen ciwidth_copy = ci_width

collapse ///
    (mean) beta_mean=beta stderr_mean=stderr ciwidth_mean=ci_width ///
    (sd) beta_sd=beta_copy stderr_sd=stderr_copy ciwidth_sd=ciwidth_copy, by(sample_size)

* Save summary table
save "01_data/siminf_summary_emc.dta", replace

* View summary in console
list sample_size beta_mean stderr_mean ciwidth_mean beta_sd stderr_sd, sepby(sample_size)

* -----------------------------------------------------
* Create figure: Beta estimate and CI width vs. Sample Size
* -----------------------------------------------------
twoway ///
    (line beta_mean sample_size, sort lwidth(medthick)) ///
    (line ciwidth_mean sample_size, sort lpattern(dash)), ///
    title("Beta Estimate and CI Width vs. Sample Size") ///
    ytitle("Value") ///
    xtitle("Sample Size") ///
    xlabel(, labsize(vsmall)) ///
    legend(label(1 "Mean Beta") label(2 "Mean CI Width"))


* Export the improved graph
graph export "01_data/fig_inf_beta_ciwidth_emc.png", replace

