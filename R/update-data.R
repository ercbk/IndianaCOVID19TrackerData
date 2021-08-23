# Update Datasets

# Sections
# 1. Set-up
# 2. Indiana-COVID-19-Tracker
# 3. Indiana-COVIDcast-Dashboard




#@@@@@@@@@@@@@@
# Set-Up ----
#@@@@@@@@@@@@@@


library(dplyr)
library(purrr)
library(stringr)


pkg_dat <- tibble(pkg_dat_ls = fs::dir_ls("data")) %>%
  mutate(pkg_dat_ls = basename(pkg_dat_ls),
         pkg_dat_ls = stringr::str_remove(pkg_dat_ls, ".rda"))




#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Indiana-COVID-19-Tracker ----
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


# d/l the directory tree for the data dir of indiana-covid-19-tracker
# got this url by parsing through the repo's tree (see datascience notebook >> misc note >> github)
trk_dat_tree <- httr::GET("https://api.github.com/repos/ercbk/Indiana-COVID-19-Tracker/git/trees/d8c0615e320c390d8e15fd674264ac5e2bb94112") %>%
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
  # keep beds_vents_complete.rds, remove any data-date matches
  filter(trk_files != "beds_vents_complete.csv" &
           !str_detect(trk_files, "data_date")) %>%
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
# load each tbl into the global env
list2env(trk_tbls, envir = .GlobalEnv)

# save tbls as .rda and export to data dir
walk(trk_dat_names, ~rio::export(.x, paste0("data/", .x, ".rda")))




#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Indiana-COVIDcast-Dashboard ----
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


## data/ ----

ccast_dat_tree <- httr::GET("https://api.github.com/repos/ercbk/Indiana-COVIDcast-Dashboard/git/trees/ae980899c74e35404f8682b8e9255437aac71efb") %>%
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
  # keep beds_vents_complete.rds, remove any data-date matches
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
# load each tbl into the global env
list2env(ccast_tbls, envir = .GlobalEnv)

# save tbls as .rda and export to data dir
walk(ccast_dat_names, ~rio::export(.x, paste0("data/", .x, ".rda")))


## data/states/ ----

ccast_stdat_tree <- httr::GET("https://api.github.com/repos/ercbk/Indiana-COVIDcast-Dashboard/git/trees/ba306756c913f807b38d963b8e1a81891fc2f1b7") %>%
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
  # keep beds_vents_complete.rds, remove any data-date matches
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
# load each tbl into the global env
list2env(ccast_sttbls, envir = .GlobalEnv)

# save tbls as .rda and export to data dir
walk(ccast_stdat_names, ~rio::export(.x, paste0("data/", .x, ".rda")))


