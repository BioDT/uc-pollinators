###### R - script to create input (resources and weather) files to run the BEEHAVE model
# main contributor Anna Wendt, University of Freiburg
# contributor of an earlier version of the WeatherDataInput() function Okan Özsoy
# modifications have been done by Jürgen Groeneveld, Tomas Martinovic, Tuomas Rossi
# the honeybee pDT has benefited from the work of the honeybee pDT team

# Import functions ----

box::use(
  terra[rast, vect, project],
)

box::use(
  R/step2_input/resources[beehave_input, modify_input_file],
  R/step2_input/weather[weather_data_input],
)

# Define rdwd download location to reduce network load
RDWD_CACHEDIR = Sys.getenv("RDWD_CACHEDIR")
if (RDWD_CACHEDIR != "") {
  options(rdwdlocdir = RDWD_CACHEDIR)
}

# Prepare input parameters ----
args <- commandArgs(trailingOnly = TRUE)
user_params <- args[1] |>
  jsonlite::parse_json(simplifyVector = TRUE)

if (!dir.exists(user_params$location_path)) {
  dir.create(user_params$location_path)
}

# user_params should contain
# id - location ID, e.g 412
# x - latitude in EPSG:4326 CRS
# y - longitude in EPSG:4326 CRS
# buffer_size - size of the buffer around points (area size in map units, typically meters)
# location_path - path to temp directory where to store inputs for computation
# input_tif_path - path to input tif file
# nectar_pollen_lookup_path - path to lookup_table.csv

# Landscape Classification Map ----
stopifnot(file.exists(user_params$input_tif_path))
stopifnot(file.exists(paste0(user_params$input_tif_path, ".aux.xml")))
input_map <-
  rast(user_params$input_tif_path)

bee_location <- vect(
  data.frame(
    id = user_params$id,
    lon = user_params$lon,
    lat = user_params$lat
  ),
  geom = c("lon", "lat"),
  crs = "EPSG:4326"
) |>
  project(input_map)

lookup_table <- read.csv(user_params$nectar_pollen_lookup_path)

# Call Input generator with different patch sizes ----
input_patches <-
  beehave_input(input_map = input_map,
               bee_location = bee_location,
               lookup_table = lookup_table,
               polygon_size = 200000,
               buffer_size = user_params$buffer_size)[[1]]

# allows to discriminate nectar and pollen resources from grassland during summer (patchtype = "Season") and the rest of the year (patchtype = "GrasslandRest")

input_patches_modified <- modify_input_file(input_patches, lookup_table)

# Write files ----
write.table(
  input_patches_modified,
  paste0(user_params$location_path, "/input_", user_params$id, ".txt"),
  sep = " ",
  row.names = FALSE
)

# Create weather input for beehave and write file ----
WeatherOutput <- weather_data_input(bee_location)

write.table(
  WeatherOutput[2],
  paste0(
    user_params$location_path,
    "/weather_",
    user_params$id,
    ".txt"
  ),
  quote = F,
  row.names = F,
  col.names = F
)
