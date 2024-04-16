# Import functions ----
box::use(
  optparse[OptionParser, add_option, parse_args],
)

box::use(
  R/step1_hq/fct_hq_json[beehave_prepare_hq_json],
)

# Define command line arguments ----

parser <- OptionParser() |>
  add_option(
    c("-i", "--input-dir"),
    type = "character",
    default = "data/input",
    help = "Path of input directory [default %default]"
  ) |>
  add_option(
    c("-o", "--output-dir"),
    type = "character",
    default = "data/output",
    help = "Path of output directory [default %default]"
  ) |>
  add_option(
    c("-m", "--map"),
    type = "character",
    action = "store",
    default = "map.tif",
    help = "Name of input map raster file [default %default]"
  ) |>
  add_option(
    c("-t", "--lookup-table"),
    type = "character",
    action = "store",
    default = "lookup_table.csv",
    help = "Name of lookup table file [default %default]"
  ) |>
  add_option(
    c("-l", "--locations"),
    type = "character",
    action = "store",
    default = "locations.csv",
    help = "Name of locations file  [default %default]"
  ) |>
  add_option(
    c("-p", "--parameters"),
    type = "character",
    action = "store",
    default = "parameters.csv",
    help = "Name of parameters file [default %default]"
  ) |>
  add_option(
    c("-b", "--buffer"),
    type = "integer",
    default = 5000L,
    help = "Buffer size in map units, typically meters [default %default]"
  ) |>
  # add_option(
  #   c("--temp"),
  #   type = "character",
  #   action = "store",
  #   default = tempdir(),
  #   help = "Folder for temporary files [default %default]"
  # ) |>
  add_option(c("--iteration"),
             type = "integer",
             default = 1L,
             help = "Iteration of optimization cycle [default %default]") |>
  add_option(c("--workdir"),
             type = "integer",
             default = NULL,
             help = "Where should the script be executed [default %default]")

inputs <- parse_args(
  parser,
  positional_arguments = TRUE,
  convert_hyphens_to_underscores = TRUE
)$options

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

beehave_prepare_hq_json(
    input_dir = inputs$input_dir,
    output_dir = inputs$output_dir,
    map = inputs$map,
    lookup_table = inputs$lookup_table,
    locations = inputs$locations,
    parameters = inputs$parameter,
    buffer = inputs$buffer,
    iteration = inputs$iteration)
