# Load libraries -----
library(foreign)
library(dplyr)
library(tibble)
library(jsonlite)

# Define parameters ----

prepath <- getwd()
input_tif_path <- paste0(prepath ,"/data/map/preidl-etal-RSE-2020_land-cover-classification-germany-2016.tif")
locations_path <- paste0(prepath ,"/data/locations/germany_grid_10km_label_cut.dbf")
temp_path <- paste0(prepath ,"/data/input/locations")
nectar_pollen_lookup_path <- paste0(prepath ,"/data/input/Preidl_lookup_table.csv")
buffer_size <- 5000 # map units (typically meters)

test_projection <- FALSE

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
        temp_path = temp_path,
        input_tif_path = input_tif_path,
        nectar_pollen_lookup_path = nectar_pollen_lookup_path
      )})

jsonlite::write_json(output_list,
                     path = paste0(prepath, "/data/input/locations.json"))
