# Load libraries -----
library(nlrx)
library(jsonlite)

# Define command line arguments ----

parser <- optparse::OptionParser() |>
  optparse::add_option(c("-p", "--user-parameters"),
                       type = "character",
                       help = "JSON containing parameters for the beehave simulation. See run_beehave.R for structure.") |>
  optparse::add_option(
    c("-v", "--netlogo-version"),
    type = "character",
    default = "6.3.0",
    help = "Netlogo version [default %default]"
  ) |>
  optparse::add_option(
    c("-n", "--netlogo-home"),
    type = "character",
    action = "store",
    default = "/NetLogo",
    help = "Netlogo home path [default %default]"
  ) |>
  optparse::add_option(
    c("-m", "--model-path"),
    type = "character",
    action = "store",
    default = "data/Beehave_BeeMapp2015_Netlogo6version_PolygonAggregation.nlogo",
    help = "Path to Beehave model file [default %default]"
  )

inputs <- optparse::parse_args(
  parser,
  positional_arguments = TRUE,
  convert_hyphens_to_underscores = TRUE
)$options

# Parse input parametersc
user_params <- inputs$user_parameters |>
  jsonlite::parse_json(simplifyVector = TRUE)


# Sys.setenv("JAVA_HOME" = "/Users/martinovic/data/BioDT/beehave/jdk-17.0.6.jdk/Contents/Home/")
# inputs <- list()
# user_params <- jsonlite::read_json("data/test/netlogo.json",
#                                    simplifyVector = TRUE)
# inputs$netlogo_version <- "6.2.0"
# inputs$netlogo_home <- "~/data/BioDT/beehave/NetLogo6.2.0/"
# inputs$model_path <-
#   "data/test/Beehave_BeeMapp2015_Netlogo6version_PolygonAggregation.nlogo"

# Create nl object which hold info on NetLogo version and model path.
nl <- nlrx::nl(
  nlversion = inputs$netlogo_version,
  nlpath = inputs$netlogo_home,
  modelpath = inputs$model_path,
  jvmmem = 7168
)

# Set default parameter values ----
params <- list(
  experiment_name = "Exp1",
  repetition = 1,
  tickmetrics = "true",
  idsetup = "setup",
  idgo = "go",
  runtime = 365 * 3,
  outpath = user_params$outpath,
  metrics = c(
    "TotalIHbees + TotalForagers",
    "(honeyEnergyStore / ( ENERGY_HONEY_per_g * 1000 ))",
    "PollenStore_g"
  ),
  variables = list(
    "N_INITIAL_BEES" = list(values = c(10000)),
    "MAX_HONEY_STORE_kg" = list(values = c(50))
  ),
  constants = list(# Syntax von Matthias Spangenberg, die funktioniert!
    # Relative path from the nlogo model file!
    "INPUT_FILE" = "\"Input_Clustertest/input_402.txt\"",
    "WeatherFile" = "\"Input_Clustertest/weather_402.txt\""),
  nseeds = 1
)

# Rewrite default parameters by user defined ----
user_params$variables <- purrr::map(user_params$variables, ~list(values = .x))
params[names(user_params)] <- user_params

stopifnot(file.exists(gsub('^.|.$', '', params$constants$INPUT_FILE)))
stopifnot(file.exists(gsub(
  '^.|.$', '', params$constants$WeatherFile
)))
# print("passed_file_check")
# Define experiment ----
nl@experiment <- nlrx::experiment(
  expname = params$experiment_name,
  outpath = params$outpath,
  repetition = params$repetition,
  tickmetrics = params$tickmetrics,
  idsetup = params$idsetup,
  idgo = params$idgo,
  runtime = params$runtime,
  variables = params$variables,
  constants = params$constants,
  metrics = params$metrics
)

# Experiment design ----
nl@simdesign <- nlrx::simdesign_distinct(nl = nl,
                                         nseeds = params$nseeds)

# Run experiment ----
results <- nlrx::run_nl_all(nl = nl)

# Store results ----
write.table(results,
            file = params$outpath,
            sep = ",",
            row.names = FALSE)
