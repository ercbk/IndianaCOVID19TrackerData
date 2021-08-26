# Convert .rda files in one dir to csv files in another dir


library(dplyr)

import_paths <- fs::dir_ls("data") %>%
  # don't want this one; it's got list columns
  purrr::discard(~stringr::str_detect(.x, "hosp_react_tab")) %>%
  unname()

# file names have a consistent format
file_names <- purrr::map(import_paths, ~stringr::str_extract(.x, "[a-z]*_[a-z]*_[a-z]*|[a-z]*_[a-z0-9]*_[a-z]*_[a-z]*"))
#

# create file paths with new data type
export_paths <- purrr::map(file_names, ~paste0("inst/extdata/", .x, ".csv"))

# convert also has args for file types used in the import and export funs it uses
purrr::walk2(import_paths, export_paths, ~rio::convert(.x, .y))

