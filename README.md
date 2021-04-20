
<!-- README.md is generated from README.Rmd. Please edit that file -->

# indianacovid19data

<!-- badges: start -->

[![R-CMD-check](https://github.com/ercbk/indianacovid19data/workflows/R-CMD-check/badge.svg)](https://github.com/ercbk/indianacovid19data/actions)
[![DOI](https://zenodo.org/badge/347752486.svg)](https://zenodo.org/badge/latestdoi/347752486)
<!-- badges: end -->

This R package provides access to most of the processed and raw datasets
from
[Indiana-COVID-19-Tracker](https://github.com/ercbk/Indiana-COVID-19-Tracker)
and
[Indiana-COVIDcast-Dashboard](https://github.com/ercbk/Indiana-COVIDcast-Dashboard).
Visualizations created using this data can be seen at the
[website](https://ercbk.github.io/Indiana-COVID-19-Website/static.html).
While most of the data in this package relates to Indiana, there are
datasets for Illinois, Michigan, and Wisconsin as well.

## Installation

You can install the latest version of indianacovid19data from Github
with:

``` r
# install.packages("remotes")
remotes::install_github("ercbk/indianacovid19data")
```

## File path to .csv format

indianacovid19data has csv file types for all its datasets in the
`inst/extdata` directory.

``` r
path_to_file("hosp_msas_line.csv")
#> [1] "C:/Users/tbats/Documents/R/win-library/4.0/indianacovid19data/extdata/hosp_msas_line.csv"
```

If the name argument is NULL, then a list of the available files in .csv
format is returned

``` r
path_to_file()
#>  [1] "age_cases_heat.csv"                "age_death_line.csv"               
#>  [3] "age_hosp_line.csv"                 "beds_vents_complete.csv"          
#>  [5] "dash_ci_line.csv"                  "goog_mob_ind.csv"                 
#>  [7] "hosp_msas_line.csv"                "hosp_react_tab.csv"               
#>  [9] "illinois_tests_complete.csv"       "ind_age_complete.csv"             
#> [11] "ind_race_complete.csv"             "ind_tests_complete.csv"           
#> [13] "median_age_bubble.csv"             "mich_tests_complete.csv"          
#> [15] "mort_hosp_line.csv"                "msa_cases100_posrate_historic.csv"
#> [17] "open_tab_reg.csv"                  "wisc_tests_complete.csv"
```
