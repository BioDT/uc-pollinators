# Load libraries ----
library(tidyverse)
# From fct_input.R
library(terra)
library(sf)
library(dplyr)
library(lubridate)
library(rdwd)

# Define rdwd download location to reduce network load
options(rdwdlocdir="data/input/DWDdata")

# Source functions ----
source("R/fct_input.R")

# Prepare input parameters ----
args <- commandArgs(trailingOnly = TRUE)
user_params <- args[1] |>
  jsonlite::parse_json(simplifyVector = TRUE)

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
    x = user_params$x,
    y = user_params$y
  ),
  geom = c("x", "y"),
  crs = "EPSG:25832"
) |> 
  project(LSCMap)

NPData <- read.csv(user_params$nectar_pollen_lookup_path)

# Call Input generator with different patch sizes ----
input_patches <- BeehaveInput(LSCMap, BeeLocation, NPData, 200000, user_params$buffer_size)[[1]]

# Write files ----
write.table(
  input_patches,
  paste0(user_params$location_path, "/input_", user_params$id, ".txt"),
  sep = " ",
  row.names = FALSE
)

# Create weather input for beehave and write file ----
WeatherOutput <- WeatherDataInput(BeeLocation)

write.table(
  WeatherOutput[2],
  paste0(user_params$location_path, "/weather_", user_params$id, ".txt"),
  quote = F,
  row.names = F,
  col.names = F
)

# write the input file for 1. the BEEHAVE Weather model
#write.table(WeatherOutput[1], "WeatherInput_405.txt" ,quote=F ,sep = "\t", row.names = FALSE)
