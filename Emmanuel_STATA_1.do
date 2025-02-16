/***********************************************************************
* Stata .do File - PPOL 6818 Assignment                                *
* Author: Emmanuel Carrasco Hernandez                                  *
* Date: February 15th, 2025                                            *
* Description: Homework: q1 q2 q3 & q4                                 *
***********************************************************************/

/* 
Set working directory based on the current user
This allows the code to run on both the professor's and student's computer
*/

if c(username)=="jacob" {
    global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

if c(username)=="52777" { 
    global wd "C:\Users\52777\Documents\Georgetown\Spring 2025\ppol_6818"
}

/***********************************************************************
* QUESTION 1: Student Attendance and Performance Analysis
***********************************************************************/
display as error "Running Question 1..."

global q1_data "$wd\week_03\04_assignment\01_data\q1_data"

use "$q1_data\student.dta", clear

* Rename variables for clarity
rename primary_teacher teacher

* Merge with teacher data
merge m:1 teacher using "$wd\week_03\04_assignment\01_data\q1_data\teacher.dta", nogen

* Merge with school data to get school location
merge m:1 school using "$wd\week_03\04_assignment\01_data\q1_data\school.dta", nogen

* ---- PART A: Calculate Mean Attendance for Schools in the South ---- *
summarize attendance if loc == "South"
display "A) The mean student attendance in southern schools is 177.48 days"

* ---- PART B: Calculate Proportion of High School Students with a Tested Subject ---- *
merge m:1 subject using "$wd\week_03\04_assignment\01_data\q1_data\subject.dta", nogen

count if level == "High"  // Total high school students
local total_high = r(N)

count if level == "High" & tested == 1  // High school students with a tested subject
local tested_high = r(N)

display "B) Proportion of high school students with a tested subject: " `tested_high'/`total_high'
display "B) Proportion of high school students with a tested subject: .44234953"

* ---- PART C: Compute Mean GPA for All Students in the District ---- *
summarize gpa
display "C) The average GPA of all students in the district is: " r(mean)
display "C) The average GPA of all students in the district is: 3.6014401"

* ---- PART D: Compute Mean Attendance for Each Middle School ---- *
keep if level == "Middle"
collapse (mean) attendance, by(school)

* Display results
list school attendance

display "D) Mean attendance per middle school:"
display "1. Joseph Darby Middle School - 177.4408 days"
display "2. Mahatma Ghandi Middle School - 177.3344 days"
display "3. Malala Yousafzai Middle School - 177.5479 days"

* End of Question 1 Analysis

/***********************************************************************
* QUESTION 2: Village Pixel Analysis
***********************************************************************/
display as error "Running Question 2..."

global q2_data "$wd\week_03\04_assignment\01_data\q2_village_pixel.dta"

use "$q2_data", clear

// ------------------------------------
// PART A: Check payout consistency within each pixel
// ------------------------------------

// Check if payout is consistent within each pixel 
bysort pixel (payout): gen pixel_consistent = (payout[_N] == payout[1])

// Check inconsistent pixels
list pixel payout pixel_consistent if pixel_consistent == 0, sepby(pixel)

// Summarize the number of consistent pixels
tab pixel_consistent


// ------------------------------------
// PART B: Identify if villages are in multiple pixels
// ------------------------------------

// Convert village (numeric) to string to avoid type mismatch errors
tostring village, generate(village_str) 

// Create a unique identifier for each village-pixel combination
gen village_pixel = village_str + "_" + pixel  

// Count the number of unique pixels per village
bysort village (pixel): gen num_pixels = (_n == 1) if pixel != pixel[_n-1] 
bysort village (pixel): replace num_pixels = sum(num_pixels) 
bysort village (pixel): replace num_pixels = num_pixels[_N]

// Create the dummy variable: 0 if the village is in one pixel, 1 if it's in multiple pixels
gen pixel_village = (num_pixels > 1)

// Display results for Part B
tab pixel_village


// ------------------------------------
// PART C: Classify Villages into 3 Categories
// ------------------------------------

// Count the number of unique payout statuses per village
bysort village payout: gen payout_varies = (_n == 1) if payout != payout[_n-1]
bysort village payout: replace payout_varies = sum(payout_varies)
bysort village: replace payout_varies = payout_varies[_N]

// Create the final category variable
gen village_category = .

// (i) Villages entirely in one pixel
replace village_category = 1 if pixel_village == 0  

// (ii) Villages in multiple pixels but with the same payout
replace village_category = 2 if pixel_village == 1 & payout_varies == 1  

// (iii) Villages in multiple pixels with different payouts
replace village_category = 3 if pixel_village == 1 & payout_varies > 1   

// Ensure all observations are categorized
tab village_category

// List all households (hhid) in category 2 (villages in multiple pixels but same payout)
list hhid village pixel payout if village_category == 2, sepby(village)

// Drop unnecessary variables to clean up
drop village_pixel num_pixels village_str pixel_village payout_varies

* End of Question 2 Analysis

/***********************************************************************
* QUESTION 3: Proposal Review Score Standardization & Ranking
***********************************************************************/
display as error "Running Question 3..."

global q3_data "$wd\week_03\04_assignment\01_data\q3_proposal_review.dta"

use "$q3_data", clear

* ---- Step 1: Compute Mean and Standard Deviation for Each Reviewer ---- *

* Reviewer 1
egen mean_r1 = mean(Review1Score), by(Rewiewer1)  // Reviewer 1 mean score
egen sd_r1 = sd(Review1Score), by(Rewiewer1)      // Reviewer 1 standard deviation

* Reviewer 2
egen mean_r2 = mean(Reviewer2Score), by(Reviewer2)  // Reviewer 2 mean score
egen sd_r2 = sd(Reviewer2Score), by(Reviewer2)      // Reviewer 2 standard deviation

* Reviewer 3
egen mean_r3 = mean(Reviewer3Score), by(Reviewer3)  // Reviewer 3 mean score
egen sd_r3 = sd(Reviewer3Score), by(Reviewer3)      // Reviewer 3 standard deviation

* ---- Step 2: Standardize Scores Using (score - mean) / std dev ---- *
gen stand_r1_score = (Review1Score - mean_r1) / sd_r1
gen stand_r2_score = (Reviewer2Score - mean_r2) / sd_r2
gen stand_r3_score = (Reviewer3Score - mean_r3) / sd_r3

* ---- Step 3: Compute Average Standardized Score ---- *
gen average_stand_score = (stand_r1_score + stand_r2_score + stand_r3_score) / 3

* ---- Step 4: Rank Proposals Based on Standardized Average Score ---- *
egen rank = rank(-average_stand_score) // Negative sign ensures highest scores get rank 1

* ---- Step 5: Drop Unnecessary Variables ---- *
drop mean_r1 sd_r1 mean_r2 sd_r2 mean_r3 sd_r3

* ---- Step 6: Display Final Dataset with Rankings ---- *
sort rank
list proposal_id rank average_stand_score stand_r1_score stand_r2_score stand_r3_score if rank <= 10 

* End of Question 3 Analysis

/***********************************************************************
* QUESTION 4: Pakistan District Data Processing
***********************************************************************/
display as error "Running Question 4..."

global excel_t21 "$wd\week_03\04_assignment\01_data\q4_Pakistan_district_table21.xlsx"

clear
tempfile table21
save `table21', replace emptyok

// ------------------------------------
// Extract Relevant Rows from Tables
// ------------------------------------

// **Tabla 1 - Extract row 6**
import excel "$excel_t21", sheet("Table 1") firstrow clear allstring
display as error "Processing Table 1 | Extracting Row 6"
keep in 6
gen table = 1
append using `table21'
save `table21', replace

// **Tabla 2 - Extract row 7**
import excel "$excel_t21", sheet("Table 2") firstrow clear allstring
display as error "Processing Table 2 | Extracting Row 7"
keep in 7
gen table = 2
append using `table21'
save `table21', replace

// **Tabla 3 - Extract row 6**
import excel "$excel_t21", sheet("Table 3") firstrow clear allstring
display as error "Processing Table 3 | Extracting Row 6"
keep in 6
gen table = 3
append using `table21'
save `table21', replace

// **Tabla 4 - Extract row 7**
import excel "$excel_t21", sheet("Table 4") firstrow clear allstring
display as error "Processing Table 4 | Extracting Row 7"
keep in 7
gen table = 4
append using `table21'
save `table21', replace

// **Tabla 5 - Extraer fila 6**
import excel "$excel_t21", sheet("Table 5") firstrow clear allstring
display as error "Processing Table 5 | Extracting Row 6"
keep in 6
gen table = 5
append using `table21'
save `table21', replace

// **Tabla 6 - Extraer fila 6**
import excel "$excel_t21", sheet("Table 6") firstrow clear allstring
display as error "Processing Table 6 | Extracting Row 6"
keep in 6
gen table = 6
append using `table21'
save `table21', replace

// **Tabla 7 - Extract row 6**
import excel "$excel_t21", sheet("Table 7") firstrow clear allstring
display as error "Processing Table 7 | Extracting Row 6"
keep in 6
gen table = 7
append using `table21'
save `table21', replace

// **Tabla 8 - Extract row 7**
import excel "$excel_t21", sheet("Table 8") firstrow clear allstring
display as error "Processing Table 8 | Extracting Row 7"
keep in 7
gen table = 8
append using `table21'
save `table21', replace

// **Tabla 9 - Extract row 7**
import excel "$excel_t21", sheet("Table 9") firstrow clear allstring
display as error "Processing Table 9 | Extracting Row 7"
keep in 7
gen table = 9
append using `table21'
save `table21', replace

// **Tabla 10 - Extract row 6**
import excel "$excel_t21", sheet("Table 10") firstrow clear allstring
display as error "Processing Table 10 | Extracting Row 6"
keep in 6
gen table = 10
append using `table21'
save `table21', replace

// **Tabla 11 - Extract row 7**
import excel "$excel_t21", sheet("Table 11") firstrow clear allstring
display as error "Processing Table 11 | Extracting Row 7"
keep in 7
gen table = 11
append using `table21'
save `table21', replace

// **Tabla 12 - Extract row 7**
import excel "$excel_t21", sheet("Table 12") firstrow clear allstring
display as error "Processing Table 12 | Extracting Row 7"
keep in 7
gen table = 12
append using `table21'
save `table21', replace

// **Tabla 13 - Extract row 6**
import excel "$excel_t21", sheet("Table 13") firstrow clear allstring
display as error "Processing Table 13 | Extracting Row 6"
keep in 6
gen table = 13
append using `table21'
save `table21', replace

// **Tabla 14 - Extract row 6**
import excel "$excel_t21", sheet("Table 14") firstrow clear allstring
display as error "Processing Table 14 | Extracting Row 6"
keep in 6
gen table = 14
append using `table21'
save `table21', replace

// **Tabla 15 - Extract row 6**
import excel "$excel_t21", sheet("Table 15") firstrow clear allstring
display as error "Processing Table 15 | Extracting Row 6"
keep in 6
gen table = 15
append using `table21'
save `table21', replace

// **Tabla 16 - Extract row 7**
import excel "$excel_t21", sheet("Table 16") firstrow clear allstring
display as error "Processing Table 16 | Extracting Row 7"
keep in 7
gen table = 16
append using `table21'
save `table21', replace

// **Tabla 17 - Extract row 7**
import excel "$excel_t21", sheet("Table 17") firstrow clear allstring
display as error "Processing Table 17 | Extracting Row 7"
keep in 7
gen table = 17
append using `table21'
save `table21', replace

// **Tabla 18 - Extract row 6**
import excel "$excel_t21", sheet("Table 18") firstrow clear allstring
display as error "Processing Table 18 | Extracting Row 6"
keep in 6
gen table = 18
append using `table21'
save `table21', replace

// **Tabla 19 - Extract row 7**
import excel "$excel_t21", sheet("Table 19") firstrow clear allstring
display as error "Processing Table 19 | Extracting Row 7"
keep in 7
gen table = 19
append using `table21'
save `table21', replace

// **Tabla 20 - Extract row 7**
import excel "$excel_t21", sheet("Table 20") firstrow clear allstring
display as error "Processing Table 20 | Extracting Row 7"
keep in 7
gen table = 20
append using `table21'
save `table21', replace

// **Table 21 - Extract row 6**
import excel "$excel_t21", sheet("Table 21") firstrow clear allstring
display as error "Processing Table 21 | Extracting Row 6"
keep in 6
gen table = 21
append using `table21'
save `table21', replace

// **Table 22 - Extract row 6**
import excel "$excel_t21", sheet("Table 22") firstrow clear allstring
display as error "Processing Table 22 | Extracting Row 6"
keep in 6
gen table = 22
append using `table21'
save `table21', replace

// **Table 23 - Extract row 7**
import excel "$excel_t21", sheet("Table 23") firstrow clear allstring
display as error "Processing Table 23 | Extracting Row 7"
keep in 7
gen table = 23
append using `table21'
save `table21', replace

// **Table 24 - Extract row 6**
import excel "$excel_t21", sheet("Table 24") firstrow clear allstring
display as error "Processing Table 24 | Extracting Row 6"
keep in 6
gen table = 24
append using `table21'
save `table21', replace

// **Table 25 - Extract row 7**
import excel "$excel_t21", sheet("Table 25") firstrow clear allstring
display as error "Processing Table 25 | Extracting Row 7"
keep in 7
gen table = 25
append using `table21'
save `table21', replace

// **Table 26 - Extract row 6**
import excel "$excel_t21", sheet("Table 26") firstrow clear allstring
display as error "Processing Table 26 | Extracting Row 6"
keep in 6
gen table = 26
append using `table21'
save `table21', replace

// **Table 27 - Extract row 6**
import excel "$excel_t21", sheet("Table 27") firstrow clear allstring
display as error "Processing Table 27 | Extracting Row 6"
keep in 6
gen table = 27
append using `table21'
save `table21', replace

// **Table 28 - Extract row 6**
import excel "$excel_t21", sheet("Table 28") firstrow clear allstring
display as error "Processing Table 28 | Extracting Row 6"
keep in 6
gen table = 28
append using `table21'
save `table21', replace

// **Table 29 - Extract row 6**
import excel "$excel_t21", sheet("Table 29") firstrow clear allstring
display as error "Processing Table 29 | Extracting Row 6"
keep in 6
gen table = 29
append using `table21'
save `table21', replace

// **Table 30 - Extract row 6**
import excel "$excel_t21", sheet("Table 30") firstrow clear allstring
display as error "Processing Table 30 | Extracting Row 6"
keep in 6
gen table = 30
append using `table21'
save `table21', replace

// **Table 31 - Extract row 7**
import excel "$excel_t21", sheet("Table 31") firstrow clear allstring
display as error "Processing Table 31 | Extracting Row 7"
keep in 7
gen table = 31
append using `table21'
save `table21', replace

// **Table 32 - Extract row 7**
import excel "$excel_t21", sheet("Table 32") firstrow clear allstring
display as error "Processing Table 32 | Extracting Row 7"
keep in 7
gen table = 32
append using `table21'
save `table21', replace

// **Table 33 - Extract row 7**
import excel "$excel_t21", sheet("Table 33") firstrow clear allstring
display as error "Processing Table 33 | Extracting Row 7"
keep in 7
gen table = 33
append using `table21'
save `table21', replace

// **Table 34 - Extract row 6**
import excel "$excel_t21", sheet("Table 34") firstrow clear allstring
display as error "Processing Table 34 | Extracting Row 6"
keep in 6
gen table = 34
append using `table21'
save `table21', replace

// **Table 35 - Extract row 6**
import excel "$excel_t21", sheet("Table 35") firstrow clear allstring
display as error "Processing Table 35 | Extracting Row 6"
keep in 6
gen table = 35
append using `table21'
save `table21', replace

// **Table 36 - Extract row 6**
import excel "$excel_t21", sheet("Table 36") firstrow clear allstring
display as error "Processing Table 36 | Extracting Row 6"
keep in 6
gen table = 36
append using `table21'
save `table21', replace

// **Table 37 - Extract row 6**
import excel "$excel_t21", sheet("Table 37") firstrow clear allstring
display as error "Processing Table 37 | Extracting Row 6"
keep in 6
gen table = 37
append using `table21'
save `table21', replace

// **Table 38 - Extract row 6**
import excel "$excel_t21", sheet("Table 38") firstrow clear allstring
display as error "Processing Table 38 | Extracting Row 6"
keep in 6
gen table = 38
append using `table21'
save `table21', replace

// **Table 39 - Extract row 7**
import excel "$excel_t21", sheet("Table 39") firstrow clear allstring
display as error "Processing Table 39 | Extracting Row 7"
keep in 7
gen table = 39
append using `table21'
save `table21', replace

// **Table 40 - Extract row 7**
import excel "$excel_t21", sheet("Table 40") firstrow clear allstring
display as error "Processing Table 40 | Extracting Row 7"
keep in 7
gen table = 40
append using `table21'
save `table21', replace

// **Table 41 - Extract row 8**
import excel "$excel_t21", sheet("Table 41") firstrow clear allstring
display as error "Processing Table 41 | Extracting Row 8"
keep in 8
gen table = 41
append using `table21'
save `table21', replace

// **Table 42 - Extract row 7**
import excel "$excel_t21", sheet("Table 42") firstrow clear allstring
display as error "Processing Table 42 | Extracting Row 7"
keep in 7
gen table = 42
append using `table21'
save `table21', replace

// **Table 43 - Extract row 6**
import excel "$excel_t21", sheet("Table 43") firstrow clear allstring
display as error "Processing Table 43 | Extracting Row 6"
keep in 6
gen table = 43
append using `table21'
save `table21', replace

// **Table 44 - Extract row 7**
import excel "$excel_t21", sheet("Table 44") firstrow clear allstring
display as error "Processing Table 44 | Extracting Row 7"
keep in 7
gen table = 44
append using `table21'
save `table21', replace

// **Table 45 - Extract row 7**
import excel "$excel_t21", sheet("Table 45") firstrow clear allstring
display as error "Processing Table 45 | Extracting Row 7"
keep in 7
gen table = 45
append using `table21'
save `table21', replace

// **Table 46 - Extract row 6**
import excel "$excel_t21", sheet("Table 46") firstrow clear allstring
display as error "Processing Table 46 | Extracting Row 6"
keep in 6
gen table = 46
append using `table21'
save `table21', replace

// **Table 47 - Extract row 7**
import excel "$excel_t21", sheet("Table 47") firstrow clear allstring
display as error "Processing Table 47 | Extracting Row 7"
keep in 7
gen table = 47
append using `table21'
save `table21', replace

// **Table 48 - Extract row 6**
import excel "$excel_t21", sheet("Table 48") firstrow clear allstring
display as error "Processing Table 48 | Extracting Row 6"
keep in 6
gen table = 48
append using `table21'
save `table21', replace

// **Table 49 - Extract row 7**
import excel "$excel_t21", sheet("Table 49") firstrow clear allstring
display as error "Processing Table 49 | Extracting Row 7"
keep in 7
gen table = 49
append using `table21'
save `table21', replace

// **Table 50 - Extract row 6**
import excel "$excel_t21", sheet("Table 50") firstrow clear allstring
display as error "Processing Table 50 | Extracting Row 6"
keep in 6
gen table = 50
append using `table21'
save `table21', replace

// **Table 51 - Extract row 6**
import excel "$excel_t21", sheet("Table 51") firstrow clear allstring
display as error "Processing Table 51 | Extracting Row 6"
keep in 6
gen table = 51
append using `table21'
save `table21', replace

// **Table 52 - Extract row 6**
import excel "$excel_t21", sheet("Table 52") firstrow clear allstring
display as error "Processing Table 52 | Extracting Row 6"
keep in 6
gen table = 52
append using `table21'
save `table21', replace

// **Table 53 - Extract row 6**
import excel "$excel_t21", sheet("Table 53") firstrow clear allstring
display as error "Processing Table 53 | Extracting Row 6"
keep in 6
gen table = 53
append using `table21'
save `table21', replace

// **Table 54 - Extract row 6**
import excel "$excel_t21", sheet("Table 54") firstrow clear allstring
display as error "Processing Table 54 | Extracting Row 6"
keep in 6
gen table = 54
append using `table21'
save `table21', replace

// **Table 55 - Extract row 6**
import excel "$excel_t21", sheet("Table 55") firstrow clear allstring
display as error "Processing Table 55 | Extracting Row 6"
keep in 6
gen table = 55
append using `table21'
save `table21', replace

// **Table 56 - Extract row 7**
import excel "$excel_t21", sheet("Table 56") firstrow clear allstring
display as error "Processing Table 56 | Extracting Row 7"
keep in 7
gen table = 56
append using `table21'
save `table21', replace

// **Table 57 - Extract row 7**
import excel "$excel_t21", sheet("Table 57") firstrow clear allstring
display as error "Processing Table 57 | Extracting Row 7"
keep in 7
gen table = 57
append using `table21'
save `table21', replace

// **Table 58 - Extract row 6**
import excel "$excel_t21", sheet("Table 58") firstrow clear allstring
display as error "Processing Table 58 | Extracting Row 6"
keep in 6
gen table = 58
append using `table21'
save `table21', replace

// **Table 59 - Extract row 6**
import excel "$excel_t21", sheet("Table 59") firstrow clear allstring
display as error "Processing Table 59 | Extracting Row 6"
keep in 6
gen table = 59
append using `table21'
save `table21', replace

// **Table 60 - Extract row 6**
import excel "$excel_t21", sheet("Table 60") firstrow clear allstring
display as error "Processing Table 60 | Extracting Row 6"
keep in 6
gen table = 60
append using `table21'
save `table21', replace

// **Table 61 - Extract row 6**
import excel "$excel_t21", sheet("Table 61") firstrow clear allstring
display as error "Processing Table 61 | Extracting Row 6"
keep in 6
gen table = 61
append using `table21'
save `table21', replace

// **Table 62 - Extract row 6**
import excel "$excel_t21", sheet("Table 62") firstrow clear allstring
display as error "Processing Table 62 | Extracting Row 6"
keep in 6
gen table = 62
append using `table21'
save `table21', replace

// **Table 63 - Extract row 6**
import excel "$excel_t21", sheet("Table 63") firstrow clear allstring
display as error "Processing Table 63 | Extracting Row 6"
keep in 6
gen table = 63
append using `table21'
save `table21', replace

// **Table 64 - Extract row 7**
import excel "$excel_t21", sheet("Table 64") firstrow clear allstring
display as error "Processing Table 64 | Extracting Row 7"
keep in 7
gen table = 64
append using `table21'
save `table21', replace

// **Table 65 - Extract row 6**
import excel "$excel_t21", sheet("Table 65") firstrow clear allstring
display as error "Processing Table 65 | Extracting Row 6"
keep in 6
gen table = 65
append using `table21'
save `table21', replace

// **Table 66 - Extract row 7**
import excel "$excel_t21", sheet("Table 66") firstrow clear allstring
display as error "Processing Table 66 | Extracting Row 7"
keep in 7
gen table = 66
append using `table21'
save `table21', replace

// **Table 67 - Extract row 6**
import excel "$excel_t21", sheet("Table 67") firstrow clear allstring
display as error "Processing Table 67 | Extracting Row 6"
keep in 6
gen table = 67
append using `table21'
save `table21', replace

// **Table 68 - Extract row 7**
import excel "$excel_t21", sheet("Table 68") firstrow clear allstring
display as error "Processing Table 68 | Extracting Row 7"
keep in 7
gen table = 68
append using `table21'
save `table21', replace

// **Table 69 - Extract row 6**
import excel "$excel_t21", sheet("Table 69") firstrow clear allstring
display as error "Processing Table 69 | Extracting Row 6"
keep in 6
gen table = 69
append using `table21'
save `table21', replace

// **Table 70 - Extract row 6**
import excel "$excel_t21", sheet("Table 70") firstrow clear allstring
display as error "Processing Table 70 | Extracting Row 6"
keep in 6
gen table = 70
append using `table21'
save `table21', replace

// **Table 71 - Extract row 7**
import excel "$excel_t21", sheet("Table 71") firstrow clear allstring
display as error "Processing Table 71 | Extracting Row 7"
keep in 7
gen table = 71
append using `table21'
save `table21', replace

// **Table 72 - Extract row 6**
import excel "$excel_t21", sheet("Table 72") firstrow clear allstring
display as error "Processing Table 72 | Extracting Row 6"
keep in 6
gen table = 72
append using `table21'
save `table21', replace

// **Table 73 - Extract row 7**
import excel "$excel_t21", sheet("Table 73") firstrow clear allstring
display as error "Processing Table 73 | Extracting Row 7"
keep in 7
gen table = 73
append using `table21'
save `table21', replace

// **Table 74 - Extract row 6**
import excel "$excel_t21", sheet("Table 74") firstrow clear allstring
display as error "Processing Table 74 | Extracting Row 6"
keep in 6
gen table = 74
append using `table21'
save `table21', replace

// **Table 75 - Extract row 6**
import excel "$excel_t21", sheet("Table 75") firstrow clear allstring
display as error "Processing Table 75 | Extracting Row 6"
keep in 6
gen table = 75
append using `table21'
save `table21', replace

// **Table 76 - Extract row 6**
import excel "$excel_t21", sheet("Table 76") firstrow clear allstring
display as error "Processing Table 76 | Extracting Row 6"
keep in 6
gen table = 76
append using `table21'
save `table21', replace

// **Table 77 - Extract row 7**
import excel "$excel_t21", sheet("Table 77") firstrow clear allstring
display as error "Processing Table 77 | Extracting Row 7"
keep in 7
gen table = 77
append using `table21'
save `table21', replace

// **Table 78 - Extract row 6**
import excel "$excel_t21", sheet("Table 78") firstrow clear allstring
display as error "Processing Table 78 | Extracting Row 6"
keep in 6
gen table = 78
append using `table21'
save `table21', replace

// **Table 79 - Extract row 7**
import excel "$excel_t21", sheet("Table 79") firstrow clear allstring
display as error "Processing Table 79 | Extracting Row 7"
keep in 7
gen table = 79
append using `table21'
save `table21', replace

// **Table 80 - Extract row 7**
import excel "$excel_t21", sheet("Table 80") firstrow clear allstring
display as error "Processing Table 80 | Extracting Row 7"
keep in 7
gen table = 80
append using `table21'
save `table21', replace

// **Table 81 - Extract row 6**
import excel "$excel_t21", sheet("Table 81") firstrow clear allstring
display as error "Processing Table 81 | Extracting Row 6"
keep in 6
gen table = 81
append using `table21'
save `table21', replace

// **Table 82 - Extract row 6**
import excel "$excel_t21", sheet("Table 82") firstrow clear allstring
display as error "Processing Table 82 | Extracting Row 6"
keep in 6
gen table = 82
append using `table21'
save `table21', replace

// **Table 83 - Extract row 6**
import excel "$excel_t21", sheet("Table 83") firstrow clear allstring
display as error "Processing Table 83 | Extracting Row 6"
keep in 6
gen table = 83
append using `table21'
save `table21', replace

// **Table 84 - Extract row 7**
import excel "$excel_t21", sheet("Table 84") firstrow clear allstring
display as error "Processing Table 84 | Extracting Row 7"
keep in 7
gen table = 84
append using `table21'
save `table21', replace

// **Table 85 - Extract row 6**
import excel "$excel_t21", sheet("Table 85") firstrow clear allstring
display as error "Processing Table 85 | Extracting Row 6"
keep in 6
gen table = 85
append using `table21'
save `table21', replace

// **Table 86 - Extract row 6**
import excel "$excel_t21", sheet("Table 86") firstrow clear allstring
display as error "Processing Table 86 | Extracting Row 6"
keep in 6
gen table = 86
append using `table21'
save `table21', replace

// **Table 87 - Extract row 6**
import excel "$excel_t21", sheet("Table 87") firstrow clear allstring
display as error "Processing Table 87 | Extracting Row 6"
keep in 6
gen table = 87
append using `table21'
save `table21', replace

// **Table 88 - Extract row 6**
import excel "$excel_t21", sheet("Table 88") firstrow clear allstring
display as error "Processing Table 88 | Extracting Row 6"
keep in 6
gen table = 88
append using `table21'
save `table21', replace

// **Table 89 - Extract row 6**
import excel "$excel_t21", sheet("Table 89") firstrow clear allstring
display as error "Processing Table 89 | Extracting Row 6"
keep in 6
gen table = 89
append using `table21'
save `table21', replace

// **Table 90 - Extract row 6**
import excel "$excel_t21", sheet("Table 90") firstrow clear allstring
display as error "Processing Table 90 | Extracting Row 6"
keep in 6
gen table = 90
append using `table21'
save `table21', replace

// **Table 91 - Extract row 7**
import excel "$excel_t21", sheet("Table 91") firstrow clear allstring
display as error "Processing Table 91 | Extracting Row 7"
keep in 7
gen table = 91
append using `table21'
save `table21', replace

// **Table 92 - Extract row 6**
import excel "$excel_t21", sheet("Table 92") firstrow clear allstring
display as error "Processing Table 92 | Extracting Row 6"
keep in 6
gen table = 92
append using `table21'
save `table21', replace

// **Table 93 - Extract row 6**
import excel "$excel_t21", sheet("Table 93") firstrow clear allstring
display as error "Processing Table 93 | Extracting Row 6"
keep in 6
gen table = 93
append using `table21'
save `table21', replace

// **Table 94 - Extract row 6**
import excel "$excel_t21", sheet("Table 94") firstrow clear allstring
display as error "Processing Table 94 | Extracting Row 6"
keep in 6
gen table = 94
append using `table21'
save `table21', replace

// **Table 95 - Extract row 7**
import excel "$excel_t21", sheet("Table 95") firstrow clear allstring
display as error "Processing Table 95 | Extracting Row 7"
keep in 7
gen table = 95
append using `table21'
save `table21', replace

// **Table 96 - Extract row 7**
import excel "$excel_t21", sheet("Table 96") firstrow clear allstring
display as error "Processing Table 96 | Extracting Row 7"
keep in 7
gen table = 96
append using `table21'
save `table21', replace

// **Table 97 - Extract row 6**
import excel "$excel_t21", sheet("Table 97") firstrow clear allstring
display as error "Processing Table 97 | Extracting Row 6"
keep in 6
gen table = 97
append using `table21'
save `table21', replace

// **Table 98 - Extract row 7**
import excel "$excel_t21", sheet("Table 98") firstrow clear allstring
display as error "Processing Table 98 | Extracting Row 7"
keep in 7
gen table = 98
append using `table21'
save `table21', replace

// **Table 99 - Extract row 7**
import excel "$excel_t21", sheet("Table 99") firstrow clear allstring
display as error "Processing Table 99 | Extracting Row 7"
keep in 7
gen table = 99
append using `table21'
save `table21', replace

// **Table 100 - Extract row 6**
import excel "$excel_t21", sheet("Table 100") firstrow clear allstring
display as error "Processing Table 100 | Extracting Row 6"
keep in 6
gen table = 100
append using `table21'
save `table21', replace

// **Table 101 - Extract row 6**
import excel "$excel_t21", sheet("Table 101") firstrow clear allstring
display as error "Processing Table 101 | Extracting Row 6"
keep in 6
gen table = 101
append using `table21'
save `table21', replace

// **Table 102 - Extract row 6**
import excel "$excel_t21", sheet("Table 102") firstrow clear allstring
display as error "Processing Table 102 | Extracting Row 6"
keep in 6
gen table = 102
append using `table21'
save `table21', replace

// **Table 103 - Extract row 6**
import excel "$excel_t21", sheet("Table 103") firstrow clear allstring
display as error "Processing Table 103 | Extracting Row 6"
keep in 6
gen table = 103
append using `table21'
save `table21', replace

// **Table 104 - Extract row 7**
import excel "$excel_t21", sheet("Table 104") firstrow clear allstring
display as error "Processing Table 104 | Extracting Row 7"
keep in 7
gen table = 104
append using `table21'
save `table21', replace

// **Table 105 - Extract row 6**
import excel "$excel_t21", sheet("Table 105") firstrow clear allstring
display as error "Processing Table 105 | Extracting Row 6"
keep in 6
gen table = 105
append using `table21'
save `table21', replace

// **Table 106 - Extract row 6**
import excel "$excel_t21", sheet("Table 106") firstrow clear allstring
display as error "Processing Table 106 | Extracting Row 6"
keep in 6
gen table = 106
append using `table21'
save `table21', replace

// **Table 107 - Extract row 6**
import excel "$excel_t21", sheet("Table 107") firstrow clear allstring
display as error "Processing Table 107 | Extracting Row 6"
keep in 6
gen table = 107
append using `table21'
save `table21', replace

// **Table 108 - Extract row 7**
import excel "$excel_t21", sheet("Table 108") firstrow clear allstring
display as error "Processing Table 108 | Extracting Row 7"
keep in 7
gen table = 108
append using `table21'
save `table21', replace

// **Table 109 - Extract row 6**
import excel "$excel_t21", sheet("Table 109") firstrow clear allstring
display as error "Processing Table 109 | Extracting Row 6"
keep in 6
gen table = 109
append using `table21'
save `table21', replace

// **Table 110 - Extract row 7**
import excel "$excel_t21", sheet("Table 110") firstrow clear allstring
display as error "Processing Table 110 | Extracting Row 7"
keep in 7
gen table = 110
append using `table21'
save `table21', replace

// **Table 111 - Extract row 6**
import excel "$excel_t21", sheet("Table 111") firstrow clear allstring
display as error "Processing Table 111 | Extracting Row 6"
keep in 6
gen table = 111
append using `table21'
save `table21', replace

// **Table 112 - Extract row 6**
import excel "$excel_t21", sheet("Table 112") firstrow clear allstring
display as error "Processing Table 112 | Extracting Row 6"
keep in 6
gen table = 112
append using `table21'
save `table21', replace

// **Table 113 - Extract row 6**
import excel "$excel_t21", sheet("Table 113") firstrow clear allstring
display as error "Processing Table 113 | Extracting Row 6"
keep in 6
gen table = 113
append using `table21'
save `table21', replace

// **Table 114 - Extract row 7**
import excel "$excel_t21", sheet("Table 114") firstrow clear allstring
display as error "Processing Table 114 | Extracting Row 7"
keep in 7
gen table = 114
append using `table21'
save `table21', replace

// **Table 115 - Extract row 7**
import excel "$excel_t21", sheet("Table 115") firstrow clear allstring
display as error "Processing Table 115 | Extracting Row 7"
keep in 7
gen table = 115
append using `table21'
save `table21', replace

// **Table 116 - Extract row 7**
import excel "$excel_t21", sheet("Table 116") firstrow clear allstring
display as error "Processing Table 116 | Extracting Row 7"
keep in 7
gen table = 116
append using `table21'
save `table21', replace

// **Table 117 - Extract row 6**
import excel "$excel_t21", sheet("Table 117") firstrow clear allstring
display as error "Processing Table 117 | Extracting Row 6"
keep in 6
gen table = 117
append using `table21'
save `table21', replace

// **Table 118 - Extract row 6**
import excel "$excel_t21", sheet("Table 118") firstrow clear allstring
display as error "Processing Table 118 | Extracting Row 6"
keep in 6
gen table = 118
append using `table21'
save `table21', replace

// **Table 119 - Extract row 6**
import excel "$excel_t21", sheet("Table 119") firstrow clear allstring
display as error "Processing Table 119 | Extracting Row 6"
keep in 6
gen table = 119
append using `table21'
save `table21', replace

// **Table 120 - Extract row 6**
import excel "$excel_t21", sheet("Table 120") firstrow clear allstring
display as error "Processing Table 120 | Extracting Row 6"
keep in 6
gen table = 120
append using `table21'
save `table21', replace

// **Table 121 - Extract row 6**
import excel "$excel_t21", sheet("Table 121") firstrow clear allstring
display as error "Processing Table 121 | Extracting Row 6"
keep in 6
gen table = 121
append using `table21'
save `table21', replace

// **Table 122 - Extract row 6**
import excel "$excel_t21", sheet("Table 122") firstrow clear allstring
display as error "Processing Table 122 | Extracting Row 6"
keep in 6
gen table = 122
append using `table21'
save `table21', replace

// **Table 123 - Extract row 6**
import excel "$excel_t21", sheet("Table 123") firstrow clear allstring
display as error "Processing Table 123 | Extracting Row 6"
keep in 6
gen table = 123
append using `table21'
save `table21', replace

// **Table 124 - Extract row 6**
import excel "$excel_t21", sheet("Table 124") firstrow clear allstring
display as error "Processing Table 124 | Extracting Row 6"
keep in 6
gen table = 124
append using `table21'
save `table21', replace

// **Table 125 - Extract row 7**
import excel "$excel_t21", sheet("Table 125") firstrow clear allstring
display as error "Processing Table 125 | Extracting Row 7"
keep in 7
gen table = 125
append using `table21'
save `table21', replace

// **Table 126 - Extract row 7**
import excel "$excel_t21", sheet("Table 126") firstrow clear allstring
display as error "Processing Table 126 | Extracting Row 7"
keep in 7
gen table = 126
append using `table21'
save `table21', replace

// **Table 127 - Extract row 6**
import excel "$excel_t21", sheet("Table 127") firstrow clear allstring
display as error "Processing Table 127 | Extracting Row 6"
keep in 6
gen table = 127
append using `table21'
save `table21', replace

// **Table 128 - Extract row 6**
import excel "$excel_t21", sheet("Table 128") firstrow clear allstring
display as error "Processing Table 128 | Extracting Row 6"
keep in 6
gen table = 128
append using `table21'
save `table21', replace

// **Table 129 - Extract row 7**
import excel "$excel_t21", sheet("Table 129") firstrow clear allstring
display as error "Processing Table 129 | Extracting Row 7"
keep in 7
gen table = 129
append using `table21'
save `table21', replace

// **Table 130 - Extract row 7**
import excel "$excel_t21", sheet("Table 130") firstrow clear allstring
display as error "Processing Table 130 | Extracting Row 7"
keep in 7
gen table = 130
append using `table21'
save `table21', replace

// **Table 131 - Extract row 6**
import excel "$excel_t21", sheet("Table 131") firstrow clear allstring
display as error "Processing Table 131 | Extracting Row 6"
keep in 6
gen table = 131
append using `table21'
save `table21', replace

// **Table 132 - Extract row 7**
import excel "$excel_t21", sheet("Table 132") firstrow clear allstring
display as error "Processing Table 132 | Extracting Row 7"
keep in 7
gen table = 132
append using `table21'
save `table21', replace

// **Table 133 - Extract row 7**
import excel "$excel_t21", sheet("Table 133") firstrow clear allstring
display as error "Processing Table 133 | Extracting Row 7"
keep in 7
gen table = 133
append using `table21'
save `table21', replace

// **Table 134 - Extract row 7**
import excel "$excel_t21", sheet("Table 134") firstrow clear allstring
display as error "Processing Table 134 | Extracting Row 7"
keep in 7
gen table = 134
append using `table21'
save `table21', replace

// **Table 135 - Extract row 7**
import excel "$excel_t21", sheet("Table 135") firstrow clear allstring
display as error "Processing Table 135 | Extracting Row 7"
keep in 7
gen table = 135
append using `table21'
save `table21', replace

// Load final dataset
use `table21', clear

// Sort table from 1 to 135
sort table

// Ensure 'table' is the first column, then 'age', then B-Z
order table TABLE21PAKISTANICITIZEN1 B-Z


// Replace all dashes with 0
foreach var of varlist B-Z {
    replace `var' = "0" if `var' == "-"
}

// **Convert B-AB to numeric format**
foreach var of varlist B-AB {
    destring `var', replace ignore(" ") force
}


// **Rename columns in intuitive order**
rename B  all_sexes_total_population
rename C  all_sexes_cni_card_obtained
rename D  all_sexes_cni_card_not_obtained

rename E  male_total_population
rename F  male_cni_card_obtained
rename G  male_cni_card_not_obtained

rename H  female_total_population
rename I  female_cni_card_obtained
rename J  female_cni_card_not_obtained

rename K  transgender_total_population
rename L  transgender_cni_card_obtained
rename M  trans_cni_card_not_obtained


// **Rename 'table' variable to something more meaningful**
rename table district_table_id

// **Rename 'TABLE21PAKIST~1' to 'age_group' for clarity**
rename TABLE21PAKIST~1 age_group

// **Check if everything is renamed correctly**
describe

* End of Question 4 Analysis

