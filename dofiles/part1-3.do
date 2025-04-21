
* sim_summary_emc.do
* Author: Emmanuel Carrasco Hernandez
* Purpose: Analyze results of simulated regressions (Part 5)

* -----------------------------------------------------
* Part 1.5: Load the simulation results
* -----------------------------------------------------
global wd "C:\Users\52777\Documents\Georgetown\Spring 2025\ppol_6818\Week 8\stata_3"
cd "$wd"

clear all
use "01_data/simdata_emc.dta", clear

* -----------------------------------------------------
* Create summary table: mean and standard deviation by sample size
* -----------------------------------------------------
preserve

* Create renamed copies of variables to avoid name conflict with collapse
gen beta_copy   = beta
gen stderr_copy = stderr

* Collapse using correct syntax: newvar = oldvar
collapse ///
    (mean) beta_mean=beta stderr_mean=stderr pval_mean=pval ci_low_mean=ci_low ci_high_mean=ci_high ///
    (sd) beta_sd=beta_copy stderr_sd=stderr_copy, by(sample_n)

* Save the summary table
save "01_data/sim_summary_emc.dta", replace

* Display summary table in console
list sample_n beta_mean stderr_mean beta_sd stderr_sd, sepby(sample_n)

restore

* -----------------------------------------------------
* Create figure: beta estimates with confidence intervals by N
* -----------------------------------------------------
twoway ///
    (rcap ci_high ci_low sample_n, sort) ///
    (scatter beta sample_n, jitter(2)), ///
    title("Beta Estimates and Confidence Intervals by Sample Size") ///
    xtitle("Sample Size") ///
    ytitle("Estimated Beta") ///
    legend(off)

* Export figure
graph export "01_data/fig_beta_variation_emc.png", replace
