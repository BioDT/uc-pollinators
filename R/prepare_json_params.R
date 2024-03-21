# Load libraries -----
# suppressPackageStartupMessages({
#   suppressWarnings({
#     library(foreign, quietly = TRUE)
#     library(dplyr, quietly = TRUE)
#     library(tidyr, quietly = TRUE)
#     library(tibble, quietly = TRUE)
#     library(jsonlite, quietly = TRUE)
#     library(optparse, quietly = TRUE)
#   })
# })

# Define command line arguments ----

parser <- optparse::OptionParser() |>
  optparse::add_option(
    c("-i", "--input-dir"),
    type = "character",
    default = "data/input",
    help = "Path of input directory [default %default]"
  ) |>
  optparse::add_option(
    c("-o", "--output-dir"),
    type = "character",
    default = "data/output",
    help = "Path of output directory [default %default]"
  ) |>
  optparse::add_option(
    c("-m", "--map"),
    type = "character",
    action = "store",
    default = "map.tif",
    help = "Name of input map raster file [default %default]"
  ) |>
  optparse::add_option(
    c("-t", "--lookup-table"),
    type = "character",
    action = "store",
    default = "NectarPollenLookUp.csv",
    help = "Name of lookup table file [default %default]"
  ) |>
  optparse::add_option(
    c("-l", "--locations"),
    type = "character",
    action = "store",
    default = "locations.csv",
    help = "Name of locations file  [default %default]"
  ) |>
  optparse::add_option(
    c("-p", "--parameters"),
    type = "character",
    action = "store",
    default = "parameters.csv",
    help = "Name of parameters file [default %default]"
  ) |>
  optparse::add_option(
    c("-b", "--buffer"),
    type = "integer",
    default = 5000L,
    help = "Buffer size in map units, typically meters [default %default]"
  ) |>
  optparse::add_option(
    c("-j", "--test-projection"),
    type = "logical",
    action = "store_true",
    default = FALSE,
    help = "Buffer size in map units, typically meters [default %default]"
  ) |>
  # optparse::add_option(
  #   c("--temp"),
  #   type = "character",
  #   action = "store",
  #   default = tempdir(),
  #   help = "Folder for temporary files [default %default]"
  # ) |>
  optparse::add_option(c("--iteration"),
                       type = "integer",
                       default = 1L,
                       help = "Iteration of optimization cycle [default %default]")

inputs <- optparse::parse_args(
  parser,
  positional_arguments = TRUE,
  convert_hyphens_to_underscores = TRUE
)$options

# Prepare file paths ----

input_tif_path <- file.path(inputs$input_dir, inputs$map)
input_lookup_path <-
  file.path(inputs$input_dir, inputs$lookup_table)
input_locations_path <-
  file.path(inputs$input_dir, inputs$locations)
input_parameters_path <- 
  file.path(inputs$input_dir, inputs$parameters)
# Backup for local testing
# inputs <- list()
# input_tif_path <-
#   "data/test/preidl-etal-RSE-2020_land-cover-classification-germany-2016.tif"
# input_lookup_path <-
#   "data/test/NectarPollenLookUp.csv"
# input_locations_path <-
#   "data/test/locations.csv"
# input_parameters_path <-
#   "data/test/parameters.csv"
# inputs$output_dir <- tempdir()
# inputs$input_dir <- "data/test"
# inputs$buffer <- 5000
# inputs$test_projection <- TRUE
# inputs$iteration <- 1

# Load locations ----
# We expect the locations CSV to have two columns "lon" and "lat" with "EPSG:4326" - "WGS 84", i.e. GPS coordinates
locations <-
  readr::read_delim(input_locations_path,
                    delim = ",",
                    col_types = list(
                      id = "i",
                      lat = "d",
                      lon = "d"
                    ))

parameters <- 
  readr::read_csv(
    file = input_parameters_path,
    col_types = list(
      Parameter = readr::col_character(),
      Value = readr::col_double(),
      `Default.Value` = readr::col_skip()
    )
  )

parameters_list <- parameters$Value |> purrr::map(~list(.x))
names(parameters_list) <- parameters$Parameter
# We used DBF files before, this is kept if needed at some point again.
  # foreign::read.dbf(
  #   input_locations_path,
  #   as.is = TRUE
  # ) |>
  # dplyr::select(-Id) |>
  # tibble::rowid_to_column("Id") |>
  # tidyr::drop_na()

# Test projection ----

if (inputs$test_projection) {
  # library(terra)
  
  lscmap <-
    terra::rast(input_tif_path)
  
  locations_sf <- terra::vect(locations,
                              geom = c("lon",
                                       "lat"),
                              crs = "EPSG:4326") |>
    terra::project(lscmap)
  
  # This part checks geographical extents, intersect point and map extent
  map_ext <- terra::ext(lscmap)
  point_ext <- terra::ext(locations_sf)
  intersect_ext <- terra::intersect(map_ext, point_ext)
  # In case the intersect extent is the same as point extent, it means all the points are inside map
  cat("\nAll points are on the map:", all.equal(as.matrix(point_ext), as.matrix(intersect_ext)), "\n")
  
  # Possible to make a plot when debugging
  # terra::plot(lscmap)
  # terra::plot(locations_sf, add = TRUE, col = "red")
}

# Create output JSON ----
# This part is used to prepare input and weather files for Beehave computed with HyperQueue

output_list <- apply(
  locations,
  MARGIN = 1,
  FUN = function(x) {
    list(
      id = x[[1]],
      lat = x[[2]],
      lon = x[[3]],
      buffer_size = inputs$buffer,
      location_path = file.path(inputs$input_dir, "locations"),
      input_tif_path = input_tif_path,
      nectar_pollen_lookup_path = input_lookup_path
    )
  }
)

jsonlite::write_json(output_list,
                     path = file.path(inputs$input_dir, "locations.json"))

# Netlogo run JSON preparation ----
# This part is used to do actual computation of the Beehave simulation with HyperQueue
# For first run this will be static on parameters and will change the input files names

netlogo_list <- apply(
  locations,
  MARGIN = 1,
  FUN = function(x) {
    list(
      outpath = file.path(
        inputs$output_dir,
        paste0("output_id", x[[1]], "_iter", inputs$iteration, ".csv")
      ),
      metrics = c(
        "TotalIHbees + TotalForagers",
        "(honeyEnergyStore / ( ENERGY_HONEY_per_g * 1000 ))",
        "PollenStore_g"
      ),
      variables = parameters_list,
      constants = list(
        "INPUT_FILE" = paste0(
          "\"",
          inputs$input_dir,
          "/locations",
          # gsub('^data/', '', inputs$locations),
          "/input_",
          x[[1]],
          ".txt\""
        ),
        "WeatherFile" = paste0(
          "\"",
          inputs$input_dir,
          "/locations",
          # gsub('^data/', '', inputs$locations),
          "/weather_",
          x[[1]],
          ".txt\""
        )
      ),
      nseeds = 1
    )
  }
)

jsonlite::write_json(netlogo_list,
                     path = file.path(inputs$input_dir, "netlogo.json"))
