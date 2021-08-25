# Update Datasets


# Notes
# 1. I'm going through the trouble of d/l repo dir trees and matching datasets (vs just hard coding each data url), because this way, if I want add a datset, its just one step, usethis::add_data(), and the new dataset is automatically included in this updating script instead of me having to add the d/l url manually each time.


# Sections
# 1. Set-up
# 2. Package data
# 3. Indiana-COVID-19-Tracker
# 4. Indiana-COVIDcast-Dashboard




#@@@@@@@@@@@@@@
# Set-Up ----
#@@@@@@@@@@@@@@


library(dplyr)
library(purrr)
library(stringr)

# get some basic tbl stats for validity checks
get_olddat_stats <- function(dat) {
  dat %>%
    summarize(nrows_95_pct = 0.95 * n(), # 0.95 cuz maybe some rows get dropped to correct an error
              ncols_pkgdat = ncol(dat))
}
get_newdat_stats <- function(dat) {
  dat %>%
    summarize(nrows = n(),
              ncols_newdat = ncol(dat))
}




#@@@@@@@@@@@@@@@@@@@@
# Package data ----
#@@@@@@@@@@@@@@@@@@@@


pkg_dat <- tibble(pkg_dat_ls = fs::dir_ls("data")) %>%
  mutate(pkg_dat_ls = basename(pkg_dat_ls),
         pkg_dat_ls = stringr::str_remove(pkg_dat_ls, ".rda"))


# load all the old datasets and get nrows, ncols to use as a check for the new datasets
import_df <- pkg_dat %>%
  mutate(dat_paths = paste0("data/", pkg_dat_ls, ".rda"))

import_ls <- rio::import_list(import_df$dat_paths)

pkg_dat_stats <- map_dfr(import_ls, ~get_olddat_stats(.x), .id = "name")
rm(import_ls)
gc()




#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Indiana-COVID-19-Tracker ----
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


# d/l dir tree of indiana-covid-19-tracker
# ** Individual directory urls change as commits are made **
trk_tree <- httr::GET("https://api.github.com/repos/ercbk/Indiana-COVID-19-Tracker/git/trees/master?recursive=1") %>%
  httr::content()

trk_tree_vec <- trk_tree$tree %>%
  map(., ~pluck(.x, 1)) %>%
  as.character()

# "data" should be the index right before the first "data/" item
trk_dat_index <- detect_index(trk_tree_vec, ~str_detect(., "data/")) - 1
trk_dat_url <- trk_tree$tree[[trk_dat_index]]$url
# d/l the directory tree for the data dir
trk_dat_tree <- httr::GET(trk_dat_url) %>%
  httr::content()

# match the names of files in tracker and files in the package
trk_dat_names <- trk_dat_tree$tree %>%
  map(~pluck(.x, 1)) %>%
  as.character() %>%
  tibble(trk_files = .) %>%
  mutate(trk_files = basename(trk_files) %>%
           # remove extensions
           stringr::str_remove("\\.[a-z]{3,4}$") %>%
           stringr::str_replace_all("-", "_")) %>%
  filter(trk_files %in% pkg_dat$pkg_dat_ls) %>%
  distinct() %>%
  arrange(trk_files) %>%
  pull(trk_files)

# names with file ext
trk_dat_files <- trk_dat_tree$tree %>%
  map(~pluck(.x, 1)) %>%
  as.character() %>%
  tibble(trk_files = .) %>%
  mutate(trk_files = basename(trk_files),
         trk_files = stringr::str_replace_all(trk_files, "-", "_"))

# match those names with names + ext
trk_pkg_files <- map_dfr(trk_dat_names, ~filter(trk_dat_files, str_detect(trk_files, .x))) %>%
  # remove any data-date matches
  filter(!str_detect(trk_files, "data_date")) %>%
  mutate(trk_files = str_replace_all(trk_files, "_", "-"),
         trk_exts = str_extract(trk_files, "\\.[a-z]{3,4}$")) %>%
  arrange(trk_files) %>%
  # create dl urls
  mutate(trk_file_urls = paste0("https://raw.githubusercontent.com/ercbk/Indiana-COVID-19-Tracker/master/data/",
                                trk_files ))


read_files <- function(u, e) {

  if (e == ".rds") {
    f <- readr::read_rds(u)
  } else {
    f <- readr::read_csv(u)
  }

}

# read files into a list
trk_tbls <- map2(trk_pkg_files$trk_file_urls,
                 trk_pkg_files$trk_exts,
                 ~read_files(.x, .y))
names(trk_tbls) <- trk_dat_names



## ind-covid-trk validity tests ----

trk_tbl_tests <- map_dfr(trk_tbls, ~get_newdat_stats(.x), .id = "name") %>%
  left_join(pkg_dat_stats, by = "name") %>%
  # TRUE == failed test
  mutate(results = if_else((ncols_newdat != ncols_pkgdat) |  (nrows < nrows_95_pct),
                          TRUE, FALSE))

if (any(trk_tbl_tests$results)) {
  trk_dat_fails <- trk_tbl_tests %>%
    filter(results == "TRUE") %>%
    pull(name)
  trk_fail_msg <- glue::glue("Indiana-COVID-19-Tracker dataset(s), {dat_fails}, failed validity")
  stop(trk_fail_msg)
}



# load each tbl into the global env
list2env(trk_tbls, envir = .GlobalEnv)

# save tbls as .rda and export to data dir
walk(trk_dat_names, ~rio::export(.x, paste0("data/", .x, ".rda")))




#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Indiana-COVIDcast-Dashboard ----
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


# d/l dir tree of indiana-covid-19-tracker
# ** Individual directory urls change as commits are made **
ccast_tree <- httr::GET("https://api.github.com/repos/ercbk/Indiana-COVIDcast-Dashboard/git/trees/master?recursive=1") %>%
  httr::content()

ccast_tree_vec <- ccast_tree$tree %>%
  map(., ~pluck(.x, 1)) %>%
  as.character()

# "data" should be the index right before the first "data/" item
ccast_dat_index <- detect_index(ccast_tree_vec, ~str_detect(., "data/")) - 1
ccast_dat_url <- ccast_tree$tree[[ccast_dat_index]]$url



## data/ ----

ccast_dat_tree <- httr::GET(ccast_dat_url) %>%
  httr::content()

# match the names of files in tracker and files in the package
ccast_dat_names <- ccast_dat_tree$tree %>%
  map(~pluck(.x, 1)) %>%
  as.character() %>%
  tibble(ccast_files = .) %>%
  mutate(ccast_files = basename(ccast_files) %>%
           # remove extensions
           stringr::str_remove("\\.[a-z]{3,4}$") %>%
           stringr::str_replace_all("-", "_")) %>%
  filter(ccast_files %in% pkg_dat$pkg_dat_ls) %>%
  distinct() %>%
  arrange(ccast_files) %>%
  pull(ccast_files)

# names with file ext
ccast_dat_files <- ccast_dat_tree$tree %>%
  map(~pluck(.x, 1)) %>%
  as.character() %>%
  tibble(ccast_files = .) %>%
  mutate(ccast_files = basename(ccast_files),
         ccast_files = stringr::str_replace_all(ccast_files, "-", "_"))

# match those names with names + ext
ccast_pkg_files <- map_dfr(ccast_dat_names, ~filter(ccast_dat_files, str_detect(ccast_files, .x))) %>%
  # remove any data-date matches
  filter(!str_detect(ccast_files, "data_date")) %>%
  mutate(ccast_files = str_replace_all(ccast_files, "_", "-"),
         ccast_exts = str_extract(ccast_files, "\\.[a-z]{3,4}$")) %>%
  arrange(ccast_files) %>%
  # create dl urls
  mutate(ccast_file_urls = paste0("https://raw.githubusercontent.com/ercbk/Indiana-COVIDcast-Dashboard/master/data/",
                                ccast_files ))

# read files into a list
ccast_tbls <- map2(ccast_pkg_files$ccast_file_urls,
                   ccast_pkg_files$ccast_exts,
                 ~read_files(.x, .y))
names(ccast_tbls) <- ccast_dat_names



### ind-ccast data/ validity tests ----

ccast_tbl_tests <- map_dfr(ccast_tbls, ~get_newdat_stats(.x), .id = "name") %>%
  left_join(pkg_dat_stats, by = "name") %>%
  # TRUE == failed test
  mutate(results = if_else((ncols_newdat != ncols_pkgdat) |  (nrows < nrows_95_pct),
                           TRUE, FALSE))

if (any(ccast_tbl_tests$results)) {
  ccast_dat_fails <- ccast_tbl_tests %>%
    filter(results == "TRUE") %>%
    pull(name)
  ccast_fail_msg <- glue::glue("Indiana-COVIDcast-Dashboard data/, {dat_fails}, failed validity")
  stop(ccast_fail_msg)
}



# load each tbl into the global env
list2env(ccast_tbls, envir = .GlobalEnv)

# save tbls as .rda and export to data dir
walk(ccast_dat_names, ~rio::export(.x, paste0("data/", .x, ".rda")))


## data/states/ ----

# "data/states" should be the index right before the first "data/states/" item
ccast_stdat_index <- detect_index(ccast_tree_vec, ~str_detect(., "data/states/")) - 1
ccast_stdat_url <- ccast_tree$tree[[ccast_stdat_index]]$url
ccast_stdat_tree <- httr::GET(ccast_stdat_url) %>%
  httr::content()

# match the names of files in tracker and files in the package
ccast_stdat_names <- ccast_stdat_tree$tree %>%
  map(~pluck(.x, 1)) %>%
  as.character() %>%
  tibble(ccast_stfiles = .) %>%
  mutate(ccast_stfiles = basename(ccast_stfiles) %>%
           # remove extensions
           stringr::str_remove("\\.[a-z]{3,4}$") %>%
           stringr::str_replace_all("-", "_")) %>%
  filter(ccast_stfiles %in% pkg_dat$pkg_dat_ls) %>%
  distinct() %>%
  arrange(ccast_stfiles) %>%
  pull(ccast_stfiles)

# names with file ext
ccast_stdat_files <- ccast_stdat_tree$tree %>%
  map(~pluck(.x, 1)) %>%
  as.character() %>%
  tibble(ccast_stfiles = .) %>%
  mutate(ccast_stfiles = basename(ccast_stfiles),
         ccast_stfiles = stringr::str_replace_all(ccast_stfiles, "-", "_"))

# match those names with names + ext
ccast_stpkg_files <- map_dfr(ccast_stdat_names, ~filter(ccast_stdat_files, str_detect(ccast_stfiles, .x))) %>%
  # remove any data-date matches
  filter(!str_detect(ccast_stfiles, "data_date")) %>%
  mutate(ccast_stfiles = str_replace_all(ccast_stfiles, "_", "-"),
         ccast_stexts = str_extract(ccast_stfiles, "\\.[a-z]{3,4}$")) %>%
  arrange(ccast_stfiles) %>%
  # create dl urls
  mutate(ccast_stfile_urls = paste0("https://raw.githubusercontent.com/ercbk/Indiana-COVIDcast-Dashboard/master/data/states/",
                                  ccast_stfiles ))

# read files into a list
ccast_sttbls <- map2(ccast_stpkg_files$ccast_stfile_urls,
                   ccast_stpkg_files$ccast_stexts,
                   ~read_files(.x, .y))
names(ccast_sttbls) <- ccast_stdat_names



### ind-ccast data/states validity tests ----

ccast_sttbl_tests <- map_dfr(ccast_sttbls, ~get_newdat_stats(.x), .id = "name") %>%
  left_join(pkg_dat_stats, by = "name") %>%
  # TRUE == failed test
  mutate(results = if_else((ncols_newdat != ncols_pkgdat) |  (nrows < nrows_95_pct),
                           TRUE, FALSE))

if (any(ccast_sttbl_tests$results)) {
  ccast_stdat_fails <- ccast_sttbl_tests %>%
    filter(results == "TRUE") %>%
    pull(name)
  ccast_stfail_msg <- glue::glue("Indiana-COVIDcast-Dashboard data/states/, {dat_fails}, failed validity")
  stop(ccast_stfail_msg)
}



# load each tbl into the global env
list2env(ccast_sttbls, envir = .GlobalEnv)

# save tbls as .rda and export to data dir
walk(ccast_stdat_names, ~rio::export(.x, paste0("data/", .x, ".rda")))


