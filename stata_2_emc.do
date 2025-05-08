// Assignment 2 — Spring 2025 — PPOL 6818
// Author: Emmanuel Carrasco Hernandez (ec1341)

// Set working directory dynamically
if c(username) == "jacob" {
    global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

if c(username) == "52777" {
    global wd "C:\Users\52777\Documents\Georgetown\Spring 2025\ppol_6818"
}

// Instal Packaged
ssc install reclink
ssc install cluster

// Set global paths
global q5_school_location "$wd\week_05\03_assignment\01_data\q5_school_location.dta"
global tz_elec_10_clean "$wd\week_05\03_assignment\01_data\Tz_elec_10_clean.dta"
global tz_elec_15_clean "$wd\week_05\03_assignment\01_data\Tz_elec_15_clean.dta"
global tz_gis "$wd\week_05\03_assignment\01_data\Tz_GIS_2015_2010_intersection.dta"
global q1_psle_raw "$wd\week_05\03_assignment\01_data\q1_psle_student_raw.dta"
global civ_popden "$wd\week_05\03_assignment\01_data\q2_CIV_populationdensity.xlsx"
global civ_section_0 "$wd\week_05\03_assignment\01_data\q2_CIV_Section_0.dta"
global q3_gps "$wd\week_05\03_assignment\01_data\q3_GPS Data.dta"
global tz_elec_10_raw "$wd\week_05\03_assignment\01_data\q4_Tz_election_2010_raw.xls"
global tz_elec_temp "$wd\week_05\03_assignment\01_data\q4_Tz_election_template.dta"
global q5_psle_data "$wd\week_05\03_assignment\01_data\q5_psle_2020_data.dta"

// Q1 

use $q1_psle_raw, clear

// Renaming raw string column for clarity
rename s raw_line
gen line_cleaned = raw_line

// Insert a delimiter "|||" before each candidate record (assuming they start with PS01)
replace line_cleaned = subinstr(line_cleaned, "PS0", "|||PS0", .)

// Trim everything before the first candidate
local start_pos = strpos(line_cleaned, "|||")
if `start_pos' > 0 {
    replace line_cleaned = substr(line_cleaned, `start_pos' + 3, .)
}

// Split by delimiter, generates line_cleaned1, line_cleaned2, ...
split line_cleaned, parse("|||")

// Drop unnecessary original variables
drop raw_line line_cleaned schoolcode

// Add ID for reshaping
gen record_id = _n
reshape long line_cleaned, i(record_id) j(rec_index) string

// Extract key variables using regex
gen school_code     = ustrregexs(1) if ustrregexm(line_cleaned, "(PS\d{7})")
gen candidate_id    = ustrregexs(1) if ustrregexm(line_cleaned, "(PS\d{7}-\d{4})")
gen prem_number     = ustrregexs(1) if ustrregexm(line_cleaned, "(\d{11})")
gen gender          = ustrregexs(1) if ustrregexm(line_cleaned, ">([MF])<")
gen student_name    = ustrregexs(1) if ustrregexm(line_cleaned, "<P>(.*?)</FONT>")
gen grade_kiswahili = ustrregexs(1) if ustrregexm(line_cleaned, "Kiswahili\s*-\s*([A-Z])")
gen grade_english   = ustrregexs(1) if ustrregexm(line_cleaned, "English\s*-\s*([A-Z])")
gen grade_maarifa   = ustrregexs(1) if ustrregexm(line_cleaned, "Maarifa\s*-\s*([A-Z])")
gen grade_math      = ustrregexs(1) if ustrregexm(line_cleaned, "Hisabati\s*-\s*([A-Z])")
gen grade_science   = ustrregexs(1) if ustrregexm(line_cleaned, "Science\s*-\s*([A-Z])")
gen grade_uraia     = ustrregexs(1) if ustrregexm(line_cleaned, "Uraia\s*-\s*([A-Z])")
gen grade_avg       = ustrregexs(1) if ustrregexm(line_cleaned, "Average Grade\s*-\s*([A-Z])")

// Clean up temp vars
drop line_cleaned* record_id rec_index

// Keep only valid rows
keep if !missing(candidate_id)

// Reorder columns for clarity
order school_code candidate_id prem_number gender student_name grade_kiswahili grade_english grade_maarifa grade_math grade_science grade_uraia grade_avg

// Q2 — Côte d'Ivoire Population Density

import excel using "$civ_popden", clear

// Remove header row (keep only real data)
keep if _n > 1

// Standardize department name to lowercase
gen department_code = strlower(A)
rename D popdensity

// Drop unused columns
drop A B C

// Handle duplicates by keeping unique department entries
duplicates drop department_code, force

// Prepare household dataset with consistent department coding
preserve

use "$civ_section_0", clear
tempfile household_fixed

// Decode department numeric code to string for matching
decode b06_departemen, gen(department_str)
drop b06_departemen
rename department_str department_code

// Save fixed household dataset
save `household_fixed'

restore

// Merge population density into household data
merge 1:m department_code using `household_fixed'

// Clean up any unmatched rows (if needed)
drop if hh1 == .

// Q3 — Enumerator Assignment based on GPS

use "$q3_gps", clear

// Set seed for reproducibility
set seed 145678

// Target number of households per enumerator (~6)
scalar target_per_enum = 6
scalar best_enum_diff = .
scalar best_enum_iteration = .

// Run 1000 iterations of K-means clustering to find best assignment
forval i = 1/1000 {
    cluster kmeans latitude longitude, k(19) name(enum_`i')
    bysort enum_`i': gen cluster_size_`i' = _N
    quietly summarize cluster_size_`i', meanonly
    scalar enum_diff = abs(r(mean) - target_per_enum)

    // Update best result if current is better
    if missing(best_enum_diff) | enum_diff < best_enum_diff {
        scalar best_enum_diff = enum_diff
        scalar best_enum_iteration = `i'
        tempfile best_enum_result
        save `best_enum_result', replace
    }
}

// Load the best assignment
use `best_enum_result', clear
display "Best iteration: " best_enum_iteration
local best_iter = best_enum_iteration

// Keep only relevant variables
keep latitude longitude id age female enum_`best_iter' cluster_size_`best_iter'
rename enum_`best_iter' enumerator_id

// Summary: number of households per enumerator
tabulate enumerator_id

// Q4 — 2010 Tanzania Election Data Cleaning

import excel using "$tz_elec_10_raw", clear

// Drop columns G and K (not needed)
drop G K

// Clean up variable names (based on row 5 labels)
foreach var of varlist * {
    rename `var' `=strtoname(`var'[5])'
}

// Drop extra header rows from Excel
drop if _n < 7

// Fill down REGION, DISTRICT, COSTITUENCY, WARD
foreach var in REGION DISTRICT COSTITUENCY WARD {
    replace `var' = `var'[_n-1] if `var' == ""
}

// Clean up TTL_VOTES (handle 'UN OPPOSSED')
replace TTL_VOTES = "" if TTL_VOTES == "UN OPPOSSED"
destring TTL_VOTES, replace

// Calculate total votes and number of candidates per ward
bysort WARD: egen total_votes = total(TTL_VOTES)
bysort WARD: gen total_cands = _N

// Keep only relevant variables
keep REGION DISTRICT COSTITUENCY WARD POLITICAL_PARTY TTL_VOTES total_votes total_cands

// Remove duplicate rows
duplicates drop

// Create ward_id grouping to avoid name overlaps across regions
egen ward_id = group(REGION DISTRICT COSTITUENCY WARD)

// Prepare POLITICAL_PARTY names for reshaping
replace POLITICAL_PARTY = subinstr(POLITICAL_PARTY, "-", "_", .)
replace POLITICAL_PARTY = subinstr(POLITICAL_PARTY, " ", "", .)

// Save unique ward-level info to merge back later
preserve
keep REGION DISTRICT COSTITUENCY WARD total_votes total_cands ward_id
duplicates drop
tempfile ward_info
save `ward_info'
restore

// Collapse votes by ward and political party
collapse (sum) TTL_VOTES, by(ward_id POLITICAL_PARTY)

// Reshape to wide format
reshape wide TTL_VOTES, i(ward_id) j(POLITICAL_PARTY) string

// Merge back ward details
merge 1:1 ward_id using `ward_info'

// Reorder and clean up variable names
order REGION DISTRICT COSTITUENCY WARD total_votes total_cands ward_id TTL*
rename TTL_VOTES* votes_*
rename *, lower
drop _merge

// Q5 — Tanzania PSLE Data + Ward Merge

// Load PSLE data
use "$q5_psle_data", clear

// Extract NECTA Centre Number (PS codes)
gen necta_centre_no = trim(ustrregexs(1)) if ustrregexm(schoolname, "(PS\d{7})")

// Extract cleaned school name (before 'Primary School')
gen pos = strpos(lower(schoolname), "primary school")
gen school_clean = trim(substr(schoolname, 1, pos - 1)) if pos > 0
replace school_clean = schoolname if pos == 0

// Extract school code from address (ensure uppercase)
gen schoolcode_check = ustrregexs(1) if ustrregexm(school_code_address, "(ps\d{7})")
replace schoolcode_check = strupper(schoolcode_check)

// Clean district names (remove CC, TC, MC, and parentheses)
rename district_name council
replace council = regexr(council, "\s*\([^)]*\)", "")
replace council = regexr(council, "\s+(CC|TC|MC)$", "")

// Remove duplicate NECTA codes
duplicates drop necta_centre_no, force

// Prepare merge dataset from school location data
preserve

use "$q5_school_location", clear

// Check and align variable names
describe

// Rename NECTACentreNo to match PSLE dataset if needed
rename NECTACentreNo necta_centre_no

// Standardize council name
replace Council = upper(Council)
replace Council = regexr(Council, "\s*\([^)]*\)", "")
replace Council = regexr(Council, "\s+(CC|TC|MC)$", "")

// Remove duplicates to clean merge base
duplicates drop necta_centre_no Council School, force
duplicates drop necta_centre_no, force

tempfile merge_data
save `merge_data'

restore

// Merge PSLE data with ward info by NECTA Centre Number
merge 1:1 necta_centre_no using `merge_data'

// Drop records only from using dataset (if any)
drop if _merge == 2

