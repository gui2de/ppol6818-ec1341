// Emmanuel Assignment 4 — Spring 2025 — PPOL 6818

// Set up working directory
if c(username) == "jacob" {
    global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

if c(username) == "52777" {
    global wd "C:\Users\52777\Documents\Georgetown\Spring 2025\ppol_6818"
}

// Part 1 — Base Setup
clear
set seed 270695  // for reproducibility

set obs 100000

gen id = _n
gen y_pre = rnormal(0, 1)  // Y ~ N(0,1)
gen te = runiform(0, 0.20)  // treatment effect between 0.0 and 0.2 SD

// Randomly assign 50% to treatment
gen rand = runiform()
sort rand
gen treat = 0
replace treat = 1 in 1/500
drop rand
sort id

// Post-treatment outcome
gen y_post = y_pre + te

// Summary statistics
sum treat y_* te

// Define globals
global outcome_pre "y_pre"
global outcome_post "y_post"
global treatment "treat"

// Power analysis parameters
local power = 0.8
local nratio = 1
local alpha = 0.05

// Calculate baseline stats
quietly sum $outcome_pre
local sd = `r(sd)'
local baseline = `r(mean)'

quietly sum $outcome_post
local treat = `r(mean)'

// Required sample size to detect 0.1 SD effect with 80% power
power twomeans `baseline' `treat', power(`power') sd(`sd') nratio(`nratio') table

local effect = round(r(delta), .01)
local samplesize = r(N)

di as error "Required sample size: `samplesize' to detect an effect size of `effect' SDs with 80% power and a 1:1 allocation ratio."

// Adjust for 15% attrition
local adjusted_size = round(`samplesize' / 0.85)
local diff = `adjusted_size' - `samplesize'

di as error "Accounting for 15% attrition, updated sample size: `adjusted_size' (`diff' additional participants)."

// Adjust if only 30% of sample can be treated
local nratio = 0.7 / 0.3  // ≈ 2.333

power twomeans `baseline' `treat', power(`power') sd(`sd') nratio(`nratio') table

local effect = round(r(delta), .01)
local samplesize = r(N)

di as error "With only 30% treated, sample size required: `samplesize' to detect an effect size of `effect' SDs with 80% power and a treatment:control ratio of 30:70."

// Part 2
// Cluster Randomization Power Calculations

//// Define cluster simulation program

capture program drop cluster_sim

program define cluster_sim, rclass
    syntax, clusters(integer) clustersize(integer) rho(real) uptake(real)
    clear

    // Generate school-level observations
    quietly set obs `clusters'
    local rho_val = `rho'
    local uptake_prop = `uptake'
    local sd_ui = sqrt(`rho_val')
    local sd_uij = sqrt(1 - `rho_val')

    gen schoolid = _n
    expand `clustersize'
    by schoolid, sort: gen student = _n

    // Cluster effect
    by schoolid (student), sort: gen u_i = rnormal(0, `sd_ui') if _n == 1
    by schoolid (student): replace u_i = u_i[1]

    // Individual error
    gen u_ij = rnormal(0, `sd_uij')

    // Randomly assign treatment at school level (50%)
    gen rand = rnormal()
    quietly su rand, detail
    local med = r(p50)
    by schoolid: gen treat = (rand <= `med')

    // Simulate imperfect uptake
    gen rand1 = rnormal()
    gen uptake_f = (rand1 <= `uptake_prop') if treat == 1

    // Treatment effect: uniform between 0.15 and 0.25
    gen te = 0
    by schoolid: replace te = uptake_f * runiform(0.15, 0.25)

    // Outcome generation
    gen y = rnormal(50, 15) + u_i + u_ij
    su y
    gen y_norm = (y - r(mean)) / r(sd)
    replace y_norm = y_norm + te if treat == 1

    regress y_norm treat, vce(cluster schoolid)

    matrix result = r(table)
    return scalar coef = result[1,1]
    return scalar pval = result[4,1]
end

////  Vary cluster size (fix clusters = 200)

clear
tempfile res
save `res', replace emptyok

local sizes "1 2 4 8 16 32 64 128 256 512"
display "Running simulations for varying cluster sizes with 200 schools..."

foreach cs of local sizes {
    simulate coef=r(coef) pval=r(pval), reps(500): ///
        cluster_sim, clusters(200) clustersize(`cs') rho(0.3) uptake(1)
    gen cluster_size = `cs'
    append using `res'
    save `res', replace
}

use `res', clear
gen reject_null = (pval <= 0.05)
tab reject_null cluster_size, col

display "Recommendation: use ~8 students per cluster to balance power and sample size."

//// Vary number of clusters (cluster size fixed = 15)

clear
tempfile res_clusters
save `res_clusters', replace emptyok

display "Running simulations for varying number of clusters..."

forvalues cs = 50(25)300 {
    simulate coef=r(coef) pval=r(pval), reps(500): ///
        cluster_sim, clusters(`cs') clustersize(15) rho(0.3) uptake(1)
    gen num_clusters = `cs'
    append using `res_clusters'
    save `res_clusters', replace
}

use `res_clusters', clear
gen reject_null = (pval <= 0.05)
tab reject_null num_clusters, col

display "With full uptake, ~50 clusters (15 students each) reach 80% power."

//// Partial uptake (70%)

clear
tempfile res_uptake
save `res_uptake', replace emptyok

display "Running simulations with 70% treatment uptake..."

forvalues cs = 50(25)300 {
    simulate coef=r(coef) pval=r(pval), reps(500): ///
        cluster_sim, clusters(`cs') clustersize(15) rho(0.3) uptake(0.7)
    gen num_clusters = `cs'
    append using `res_uptake'
    save `res_uptake', replace
}

use `res_uptake', clear
gen reject_null = (pval <= 0.05)
tab reject_null num_clusters, col

display "With 70% uptake, about 100 clusters (15 per school) are needed for 80% power."

// Part 3 — De-biasing Estimates


capture program drop strata_sim_ec
program define strata_sim_ec, rclass
    syntax, strata_num(integer) samp_within_strata(integer)

    clear
    set obs `strata_num'
    gen strata_id = _n
    gen strata_effect = rnormal(0, 2)

    expand `samp_within_strata'
    gen indiv_id = _n

    // Continuous covariates
    gen confounder_var = rnormal(10, 1)          // affects both Y and treatment
    gen treat_assign = (confounder_var <= 10)    // makes treatment tied to confounder
    gen outcome_only_var = rnormal(10, 1)        // affects only Y
    gen treatment_only_var = rnormal(3, 1)       // affects only treatment
    gen treatment_effect = treatment_only_var + runiform(2, 3)

    // Outcome variable
    gen y_outcome = 5 * outcome_only_var + 2.1 * confounder_var + treat_assign * treatment_effect + strata_effect

    // Regressions
    reg y_outcome confounder_var treat_assign i.strata_id
    matrix R = r(table)
    return scalar coef1 = R[1,1]

    reg y_outcome confounder_var outcome_only_var i.strata_id
    matrix R = r(table)
    return scalar coef2 = R[1,1]

    reg y_outcome confounder_var outcome_only_var treat_assign treatment_effect i.strata_id
    matrix R = r(table)
    return scalar coef3 = R[1,1]

    reg y_outcome confounder_var i.treat_assign##c.treatment_effect i.strata_id
    matrix R = r(table)
    return scalar coef4 = R[1,1]

    reg y_outcome confounder_var outcome_only_var i.treat_assign##c.treatment_effect i.strata_id
    matrix R = r(table)
    return scalar coef5 = R[1,1]

    return scalar sample_n = _N
end

// Run simulations across different sample sizes
clear
tempfile results_ec
save `results_ec', replace emptyok

forvalues s = 10(25)250 {
    simulate m1=r(coef1) m2=r(coef2) m3=r(coef3) m4=r(coef4) m5=r(coef5) sample_n=r(sample_n), reps(500): ///
        strata_sim_ec, strata_num(6) samp_within_strata(`s')

    append using `results_ec'
    save `results_ec', replace
}

// Summarize means and SDs
estpost tabstat m1 m2 m3 m4 m5, stat(mean sd) by(sample_n) elabels
estimates store summary_ec

// Export summary table (update to your directory or comment if not needed)
* esttab summary_ec using "summary_table_ec.tex", ///
*     cells("m1(fmt(%9.2f) par(%9.2f)) m2(fmt(%9.2f) par(%9.2f)) m3(fmt(%9.2f) par(%9.2f)) m4(fmt(%9.2f) par(%9.2f)) m5(fmt(%9.2f) par(%9.2f))") ///
*     unstack varlabels(`e(labels)') nonumb noobs replace fragment
ssc install vioplot
// Violin plot of confounder beta estimates
vioplot m1, over(sample_n) horizontal title("Violin Plot: Confounder Beta Ec1341") subtitle("True Effect = 2.1") ylabel(, angle(0))


twoway ///
    (kdensity m1 if sample_n == 60, lcolor(navy)) ///
    (kdensity m1 if sample_n == 360, lcolor(purple)) ///
    (kdensity m1 if sample_n == 660, lcolor(teal)) ///
    , xline(2.1, lcolor(red) lpattern(dash)) ///
      legend(label(1 "N = 60") label(2 "N = 360") label(3 "N = 660")) ///
      ylabel(, valuelabel) ///
      ytitle("Density") ///
      title("Density of Confounder Beta Across Sample Sizes Ec1341")

