* popdata_emc.do
* Author: Emmanuel Carrasco Hernandez
* Purpose: Create a fixed population with generated X and Y variables

* -----------------------------------------------------
* Part 1: Data generating process for X and outcome Y
* -----------------------------------------------------
* - X: standard normal
* - error: standard normal
* - Y = 1.8 * X + error

* Set working directory
global wd "C:\Users\52777\Documents\Georgetown\Spring 2025\ppol_6818\Week 8"
cd "$wd\stata_3"

clear all
set more off
set seed 24042001  // Ensures reproducibility

* Generate 10,000 observations
set obs 10000

* Create independent variable X
gen X = rnormal()

* Create error term
gen error = rnormal()

* Generate outcome variable Y
gen Y = 1.8*X + error

* -----------------------------------------------------
* Save the dataset with a personalized name
* -----------------------------------------------------
cap mkdir "01_data"
save "01_data\popdata_emc.dta", replace
