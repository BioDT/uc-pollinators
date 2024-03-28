###### R - script to create input (resources and weather) files to run the BEEHAVE model
# main contributor Anna Wendt, University of Freiburg
# contributor of an earlier version of the WeatherDataInput() function Okan Özsoy
# modifications have been done by Jürgen Groeneveld, Tomas Martinovic, Tuomas Rossi
# the pollination pDT has benefitted from the work of the pollination pDT team


# Load libraries ----
library(tidyverse)
# From fct_input.R
library(terra)
library(sf)
library(dplyr)
library(lubridate)
library(rdwd)

# Define rdwd download location to reduce network load
RDWD_CACHEDIR = Sys.getenv("RDWD_CACHEDIR")
if (RDWD_CACHEDIR != "") {
  options(rdwdlocdir = RDWD_CACHEDIR)
}

# Source functions ----
source("/R/fct_beehave_input.R")

# Prepare input parameters ----
args <- commandArgs(trailingOnly = TRUE)
user_params <- args[1] |>
  jsonlite::parse_json(simplifyVector = TRUE)

if (!dir.exists(user_params$location_path)) {
  dir.create(user_params$location_path)
}

# user_parames should contain
# id - location ID, e.g 412
# x - latitude in EPSG:25832 CRS
# y - longitude in EPSG:25832 CRS
# buffer_size - size of the buffer around points (area size in map units, typically meters)
# location_path - path to temp directory where to store inputs for computation
# input_tif_path - path to input tif file
# nectar_pollen_lookup_path - path to NectarPollenLookUp.csv

# Landscape Classification Map ----
LSCMap <-
  rast(user_params$input_tif_path)

RefCRS <- crs(LSCMap, parse = FALSE)

BeeLocation <- vect(
  data.frame(
    id = user_params$id,
    lon = user_params$lon,
    lat = user_params$lat
  ),
  geom = c("lon", "lat"),
  crs = "EPSG:4326"
) |>
  project(LSCMap)

NPData <- read.csv(user_params$nectar_pollen_lookup_path)

# Call Input generator with different patch sizes ----
input_patches <-
  BeehaveInput(LSCMap, BeeLocation, NPData, 200000, user_params$buffer_size)[[1]]

# allows to discriminate nectar and pollen resources from grassland during summer (patchtype = "Season") and the rest of the year (patchtype = "GrasslandRest")

input_patches_modified <- modify_Inputfile (input_patches, NPData)

# Write files ----
write.table(
  input_patches_modified,
  paste0(user_params$location_path, "/input_", user_params$id, ".txt"),
  sep = " ",
  row.names = FALSE
)

# Create weather input for beehave and write file ----
WeatherOutput <- WeatherDataInput(BeeLocation)

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

# write the input file for 1. the BEEHAVE Weather model
#write.table(WeatherOutput[1], "WeatherInput_405.txt" ,quote=F ,sep = "\t", row.names = FALSE)
