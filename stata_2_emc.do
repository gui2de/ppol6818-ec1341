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

