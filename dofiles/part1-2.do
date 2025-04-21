* simdata_emc.do
* Author: Emmanuel Carrasco Hernandez
* Purpose: Simulate regressions from a fixed population

* -----------------------------------------------------
* Set working directory to folder containing population data
* -----------------------------------------------------
global wd "C:\Users\52777\Documents\Georgetown\Spring 2025\ppol_6818\Week 8\stata_3"
cd "$wd"

* Make sure results folder exists
cap mkdir "01_data"

clear all
set more off

* -----------------------------------------------------
* Part 1.3: Define a program to simulate regression results
* -----------------------------------------------------
* This program:
* (a) Loads the fixed population
* (b) Randomly samples a subset based on user input
* (c) Runs a regression of Y on X
* (e) Returns key statistics: N, beta, SEM, p-value, confidence intervals

capture program drop run_regression

program define run_regression, rclass
    syntax, samplesize(integer)

    * Load the fixed population
    use "01_data/popdata_emc.dta", clear

    * Draw a random sample of given size
    sample `samplesize', count

    * Run regression of Y on X
    quietly regress Y X

    * Extract results from the regression table
    matrix stats = r(table)

    * Store statistics in r()
    return scalar beta     = _b[X]
    return scalar stderr   = _se[X]
    return scalar pval     = stats[4,1]
    return scalar ci_low   = stats[5,1]
    return scalar ci_high  = stats[6,1]
    return scalar N        = e(N)
end

* -----------------------------------------------------
* Part 1.4: Run the program using simulate for various sample sizes
* -----------------------------------------------------
* Using 500 repetitions for each: N = 10, 100, 1,000, and 10,000

local sizes "10 100 1000 10000"

* Temporary file to collect all results
tempfile combined_results
save `combined_results', emptyok

foreach n of local sizes {
    di ">>> Running 500 reps for sample size = `n'"

    simulate beta=r(beta) stderr=r(stderr) pval=r(pval) ci_low=r(ci_low) ci_high=r(ci_high) N=r(N), ///
        reps(500) nodots: run_regression, samplesize(`n')

    * Add variable to indicate the sample size
    gen sample_n = `n'

    * Save individual result set
    save "01_data/simemc_`n'.dta", replace

    * Append to full dataset
    append using `combined_results'
    save `combined_results', replace
}

* Load final dataset with 2,000 simulation results
use `combined_results', clear

* Clean in case of any missing values
drop if missing(beta)

* Save final dataset 
save "01_data/simdata_emc.dta", replace
