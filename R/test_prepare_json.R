# Load libraries -----
library(foreign)
library(dplyr)
library(tibble)
library(jsonlite)

# Define parameters ----

# Define paths
prepath <- getwd()
input_tif_path <- file.path(prepath ,"data/map/preidl-etal-RSE-2020_land-cover-classification-germany-2016.tif")
locations_path <- file.path(prepath ,"data/locations/germany_grid_10km_label_cut.dbf")
nectar_pollen_lookup_path <- file.path(prepath ,"data/input/Preidl_lookup_table.csv")
if (Sys.getenv("TEMP_PATH") == "") {
  temp_path <- file.path(prepath, "data/input")
} else {
  temp_path <- Sys.getenv("TEMP_PATH")
}
output_path <- file.path(temp_path, "output")
location_path <- file.path(temp_path, "locations")

if (Sys.getenv("ITERATION") == "") {
  iteration <- 1
} else {
  iteration <- Sys.getenv("ITERATION")
}
buffer_size <- 5000 # map units (typically meters)

test_projection <- TRUE

# Prepare input parameters ----
locations <- foreign::read.dbf(locations_path,
                               as.is = TRUE) |> 
  dplyr::select(-Id) |> 
  tibble::rowid_to_column("Id")

# Test projection ----

if (test_projection) {
  library(terra)
  library(sf)
  
  lscmap <-
    rast(input_tif_path)
  
  locations_sf <- terra::vect(
    locations,
    geom = c("POINT_X",
             "POINT_Y"),
    crs = "EPSG:25832"
  ) |>
    terra::project(lscmap)
  
  plot(lscmap); plot(locations_sf, add = TRUE)
}

# Create output JSON ----

output_list <- apply(locations,
      MARGIN = 1,
      FUN = function(x){list(
        id = x[[1]],
        x = x[[2]],
        y = x[[3]],
        buffer_size = buffer_size,
        location_path = location_path,
        input_tif_path = input_tif_path,
        nectar_pollen_lookup_path = nectar_pollen_lookup_path
      )})

jsonlite::write_json(output_list,
                     path = file.path(temp_path, "locations.json"))

# Netlogo run JSON preparation ----

# For first run this will be static on parameters and will change the input files names
list(
  outpath = file.path(output_path, paste0("output_id", id, "_iter", iteration, ".csv")),
  metrics = c(
    "TotalIHbees + TotalForagers",
    "(honeyEnergyStore / ( ENERGY_HONEY_per_g * 1000 ))",
    "PollenStore_g"
  ),
  variables = list(
    "N_INITIAL_BEES" = list(values = c(10000)),
    "MAX_HONEY_STORE_kg" = list(values = c(50))
  ),
  constants = list("INPUT_FILE" = paste0("\"", location_path,"/input_", id,".txt\""),
                   "WeatherFile" = paste0("\"", location_path,"/weather_", id,".txt\"")),
  nseeds = 1
)
