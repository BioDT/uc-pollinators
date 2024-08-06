###### R - script to create input (resources and weather) files to run the BEEHAVE model
# main contributor Anna Wendt, University of Freiburg
# contributor of an earlier version of the WeatherDataInput() function Okan Özsoy
# modifications have been done by Jürgen Groeneveld, Tomas Martinovic, Tuomas Rossi
# the honeybee pDT has benefited from the work of the honeybee pDT team

# Import functions ----
box::use(
  terra[crds, project],
  dplyr[mutate, filter, pull, left_join, rename, select, slice, n],
  rdwd[nearbyStations, dataDWD],
  lubridate[as_date],
)

# Function to create a weatherinput file for the beehave model
#' @export
weather_data_input <- function(bee_location,
                               from_date = "2016-01-01",
                               to_date = "2016-12-31") {
  # transform input coordinates to degrees
  TrachtnetConv <- project(bee_location, "epsg:4326")
  Coordinates <- as.data.frame(crds(TrachtnetConv))
  
  # Read the station data
  WeatherStations <- nearbyStations(
    Coordinates$y,
    Coordinates$x,
    radius = 50,
    res = "daily", var = "kl", per = "historical", mindate = to_date
  ) |>
    # select only stations that started measuring before 2016
    filter(von_datum < from_date)
  
  # check through the stations for NA values in data
  for (i in 1:nrow(WeatherStations)) {
    weather_data <- dataDWD(WeatherStations$url[i], varnames = TRUE, quiet = TRUE) |>
      select(MESS_DATUM,
             SDK.Sonnenscheindauer,
             TXK.Lufttemperatur_Max) |>
      # mutate(MESS_DATUM = as_date(MESS_DATUM)) |>
      filter(MESS_DATUM >= as.POSIXct(from_date, tz = "GMT"),
             MESS_DATUM <= as.POSIXct(to_date, tz = "GMT")) 

    # breaks when file with no NAs in SDK found
    if (anyNA(weather_data$SDK.Sonnenscheindauer) == FALSE & length(weather_data$SDK.Sonnenscheindauer) > 0) break
    
    # if all stations contain NA values give warning
    if (i == length(WeatherStations$Stations_id)) {
      warning(paste("Final selected weather station includes NA values. No stations found without any NA within 50km distance. Station ID:", WeatherStations$Stations_id[i]))
    }
  }
  
  # Add station id and day number
  weather_data <- weather_data |>
    rename(Date = MESS_DATUM,
           T_max = TXK.Lufttemperatur_Max,
           Sun_hours = SDK.Sonnenscheindauer) |>
    mutate(Station_id = WeatherStations$Stations_id[i],
           Day = 1:n(),
           .before = Date) |>
    # Use only sun hours where max temperature is above 15 degrees celsium
    mutate(Sun_hours = ifelse(T_max < 15, 0, Sun_hours))
  
  # create vector for BEEHAVE weather input with sunshine hours
  weather_file <- paste("[", paste(weather_data$Sun_hours, collapse = " "), "]")
  
  return(list(weather_data, weather_file))
}
