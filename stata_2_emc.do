// Assignment 2 — Spring 2025 — PPOL 6818
// Author: Emmanuel Carrasco Hernandez (ec1341)
// Purpose: Set up working directories and global paths for data analysis

// Set working directory dynamically
if c(username) == "jacob" {
    global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

if c(username) == "52777" {
    global wd "C:\Users\52777\Documents\Georgetown\Spring 2025\ppol_6818"
}

// IF PACKAGES NOT INSTALLED, PLEASE INSTALL BELOW BY UNCOMMENTING
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

