* siminf_emc.do
* Author: Emmanuel Carrasco Hernandez
* Purpose: Full simulation of sampling noise from an infinite superpopulation (Part 2)

* -----------------------------------------------------
* Set working directory
* -----------------------------------------------------
global wd "C:\Users\52777\Documents\Georgetown\Spring 2025\ppol_6818\Week 8\stata_3"
cd "$wd"

clear all
set more off

* -----------------------------------------------------
* PART 2.1 — Define program that generates new data & runs regression
* -----------------------------------------------------
capture program drop sim_infinite
program define sim_infinite, rclass
    syntax, sampsize(integer)

    * Generate new dataset with size N = sampsize
    clear
    set obs `sampsize'

    * Data generating process: X ~ N(0,1), Y = 1.8*X + error
    gen X = rnormal()
    gen error = rnormal()
    gen Y = 1.8*X + error

    * Run regression
    quietly regress Y X
    matrix stats = r(table)

    * Return results
    return scalar beta     = _b[X]
    return scalar sem      = _se[X]
    return scalar pvalue   = stats[4,1]
    return scalar ci_lower = stats[5,1]
    return scalar ci_upper = stats[6,1]
    return scalar N        = e(N)
end

* -----------------------------------------------------
* PART 2.2 — Simulate for multiple sample sizes
* -----------------------------------------------------

* Define sample sizes:
local powers ""
forvalues i = 2/21 {
    local size = 2^`i'
    local powers "`powers' `size'"
}

local extras "10 100 1000 10000 100000 1000000"

* Create temp file to store results
tempfile results_inf
save `results_inf', emptyok

* Run simulations for powers of 2
foreach n of local powers {
    di ">>> Running 500 reps for N = `n' (power of 2)"
    
    simulate beta=r(beta) stderr=r(sem) pval=r(pvalue) ci_low=r(ci_lower) ci_high=r(ci_upper), ///
        reps(500) nodots: sim_infinite, sampsize(`n')

    gen sample_size = `n'
    save "01_data/siminf_`n'_emc.dta", replace

    append using `results_inf'
    save `results_inf', replace
}

* Run simulations for extra sample sizes
foreach n of local extras {
    di ">>> Running 500 reps for N = `n' (extra size)"
    
    simulate beta=r(beta) stderr=r(sem) pval=r(pvalue) ci_low=r(ci_lower) ci_high=r(ci_upper), ///
        reps(500) nodots: sim_infinite, sampsize(`n')

    gen sample_size = `n'
    save "01_data/siminf_`n'_emc.dta", replace

    append using `results_inf'
    save `results_inf', replace
}

* Save the full dataset with 13,000 results
use `results_inf', clear
save "01_data/siminf_emc.dta", replace
