
#'FARS Dataframe Creator
#'
#'This function checks for the presence of a file, and outputs
#'  a data frame object of the data if the file exists. If the file
#'  does not exist it will output an error message.
#'It uses functions from the 'readr' and 'dplyr' packages.
#'
#'@param filename A character string containing a CSV file path that will be
#'  checked and used to create a data frame. If the file is in the same
#'  directory as the R project, it could simply be a CSV file name.
#'
#'@return A data frame with the contents of the CSV for which a file path was
#'  given.
#'
#'@note Inputting a file path improperly, or a file path to a file that does not
#'  exist, will result in an error.
#'
#'@importFrom readr read_csv
#'@importFrom dplyr tbl_df
#'
#'@examples
#'\dontrun{fars_read("myfile.csv")}
#'\dontrun{fars_read("C:/Users/Username/Documents/directoryfolder/myfile.csv")}
#'
#'@export
fars_read <- function(filename) {
  if(!file.exists(filename))
    stop("file '", filename, "' does not exist")
  data <- suppressMessages({
    readr::read_csv(filename, progress = FALSE)
  })
  dplyr::tbl_df(data)
}

#'FARS File Name Creator
#'
#'A simple function that takes a year as a parameter and returns a
#'  file name that includes the year.
#'
#'@param year An integer, numeric value, or numeric string, that represents a
#'  year for which a file name will be built. This value should be a whole
#'  number.
#'
#'@return A character string that defines the file name of the inputted year's
#'  data.
#'
#'@note Non-whole numbers will be truncated. Inputting character strings
#'  will result in errors.
#'
#'@examples
#'\dontrun{make_filename(2013)}
#'\dontrun{make_filename("2014")}
#'
#'@export
make_filename <- function(year) {
  year <- as.integer(year)
  sprintf("accident_%d.csv.bz2", year)
}

#'FARS Year Reader
#'
#'This function takes a vector of years, and returns a vector of data frames
#'  that correspond to the inputted years' data. Each data frame is simplified
#'  such that each observation only gives the month and year of the observation.
#'It uses functions from the 'magrittr' and 'dplyr' package, as well as the functions
#'  'make_filename' and 'fars_read' defined earlier.
#'
#'@param years A character vector, numeric vector, or integer vector containing
#'  the years for which data will be read.
#'
#'@return A vector containing a data frame for each inputted year's data,
#'  where each observation only contains its month and year.
#'
#'@note Inputting years for which there is no data, or years that are improperly
#'  formatted, will result in errors.
#'
#'@importFrom fars make_filename
#'@importFrom dplyr mutate select
#'@importFrom magrittr %>%
#'
#'@examples
#'\dontrun{fars_read_years(c(2013,2014,2015))}
#'\dontrun{fars_read_years(c("2013","2014"))}
#'
#'@export
fars_read_years <- function(years) {
  lapply(years, function(year) {
    file <- make_filename(year)
    tryCatch({
      dat <- fars_read(file)
      dplyr::mutate(dat, year = year) %>%
        dplyr::select(MONTH, year)
    }, error = function(e) {
      warning("invalid year: ", year)
      return(NULL)
    })
  })
}

#'FARS Year Summarize
#'
#'This function takes a vector of years, and returns a single data frame that
#'  summarizes each year by total fatalities in each month.
#'It uses functions from the 'magrittr' and 'dplyr' package, as well as the
#'  function 'fars_summarize_years' defined earlier.
#'
#'@param years A character vector, numeric vector, or integer vector containing
#'  the years for which data will be read and summarized.
#'
#'@return A data frame summarizing total number of fatalities by year and month.
#'
#'@note Inputting years for which there is no data, or years that are improperly
#'  formatted, will result in errors.
#'
#'@importFrom dplyr bind_rows group_by summarize n
#'@importFrom tidyr spread
#'@importFrom magrittr %>%
#'
#'@examples
#'
#'\dontrun{fars_summarize_years(c(2013,2014,2015))}
#'\dontrun{fars_summarize_years(c("2013","2014"))}
#'
#'@export
fars_summarize_years <- function(years) {
  dat_list <- fars_read_years(years)
  dplyr::bind_rows(dat_list) %>%
    dplyr::group_by(year, MONTH) %>%
    dplyr::summarize(n = dplyr::n()) %>%
    tidyr::spread(year, n)
}
#'FARS Year Summarize
#'
#'This function plots traffic fatalities for a specified year onto a specified
#'  state.
#'It uses functions from the 'maps', 'graphics', and 'dplyr' package, as well as
#'  the function 'fars_read' and 'make_filename' defined earlier.
#'
#'@param year A character, numeric, or integer that gives the year for which
#'  data should be plotted.
#'@param state.num A character, numeric, or integer that gives the number
#'  corresponding to the state for which data should be plotted.
#'
#'@return a plot of the selected state corresponding to the inputted state.num,
#'  and points indicating the locations of the traffic fatalities of the
#'  selected year.
#'
#'@note Inputting years or states for which there is no data, or a year or
#'  state.num that are improperly formatted, will result in errors.
#'
#'@importFrom dplyr filter
#'@importFrom maps map
#'@importFrom graphics points
#'
#'@examples
#'\dontrun{fars_map_state(2,2013)}
#'\dontrun{fars_map_state("23","2014")}
#'
#'@export
fars_map_state <- function(state.num, year) {
  filename <- make_filename(year)
  data <- fars_read(filename)
  state.num <- as.integer(state.num)

  if(!(state.num %in% unique(data$STATE)))
    stop("invalid STATE number: ", state.num)
  data.sub <- dplyr::filter(data, STATE == state.num)
  if(nrow(data.sub) == 0L) {
    message("no accidents to plot")
    return(invisible(NULL))
  }
  is.na(data.sub$LONGITUD) <- data.sub$LONGITUD > 900
  is.na(data.sub$LATITUDE) <- data.sub$LATITUDE > 90
  with(data.sub, {
    maps::map("state", ylim = range(LATITUDE, na.rm = TRUE),
              xlim = range(LONGITUD, na.rm = TRUE))
    graphics::points(LONGITUD, LATITUDE, pch = 46)
  })
}
