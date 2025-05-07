* Set up working directory for jacob
if c(username) == "jacob" {
    global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

* Set up working directory and run scripts for 52777
if c(username) == "52777" {
    global wd "C:\Users\52777\Documents\Georgetown\Spring 2025\ppol_6818\Week 8"
    cd "$wd\stata_3"

    ********************************************************************************
    * Part 1
    do "$wd\stata_3\01_data\siminf_summary_emc.do"
    do "$wd\stata_3\01_data\siminf_emc.do"
    do "$wd\stata_3\01_data\simdata_emc.do"

    * Part 2
    do "$wd\stata_3\01_data\sim_summary_emc.do"
    do "$wd\stata_3\01_data\popdata_emc.do"
    do "$wd\stata_3\01_data\combined_summary_emc.do"

    * Build README.md and HTML from README.txt
    ********************************************************************************
    dyntext "$wd\stata_3\00_script\README.txt", saving("$wd\stata_3\00_script\README.md") replace
    dyndoc "$wd\stata_3\00_script\README.md", saving("$wd\stata_3\00_script\README.html") replace
}
