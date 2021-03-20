#' Get file path to .csv files
#'
#' indianacovid19data has csv file types for all its datasets in the `inst/extdata`
#' directory. This function makes them easy to access.
#'
#' @details The csv file for [hosp_react_tab] doesn't include the list columns.
#'
#' @param path Name of file in quotes with extension. If `NULL`, the example files will be listed.
#'
#' @source The function is the same as [palmerpenguins::path_to_file()] with a few edits.
#'
#' @export
#' @examples
#' path_to_file()
#' path_to_file("hosp_msas_line.csv")
#' head(read.csv(path_to_file("hosp_msas_line.csv")))

path_to_file <- function(path = NULL) {
  if (is.null(path)) {
    dir(system.file("extdata", package = "indianacovid19data"))
  } else {
    system.file("extdata", path, package = "indianacovid19data", mustWork = TRUE)
  }
}
