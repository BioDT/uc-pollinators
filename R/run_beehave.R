# Load libraries -----
library(nlrx)
library(jsonlite)

# Prepare input parameters ----
args <- commandArgs(trailingOnly = TRUE)
user_params <- args[1] |>
  jsonlite::parse_json(simplifyVector = TRUE)

# Create nl object which hold info on NetLogo version and model path.
nl <- nlrx::nl(
  nlversion = Sys.getenv("NETLOGO_VERSION"),
  nlpath = file.path(Sys.getenv("NETLOGO_HOME")),
  modelpath = file.path(Sys.getenv("MODEL_PATH")),
  jvmmem = 7168
)

# Set default parameter values ----
params <- list(
  experiment_name = "Exp1",
  repetition = 1,
  tickmetrics = "true",
  idsetup = "setup",
  idgo = "go",
  runtime = 365*3,
  outpath = file.path("data/output/Result_table.csv"),
  metrics = c(
    "TotalIHbees + TotalForagers",
    "(honeyEnergyStore / ( ENERGY_HONEY_per_g * 1000 ))",
    "PollenStore_g"
  ),
  variables = list(
    "N_INITIAL_BEES" = list(values = c(10000)),
    "MAX_HONEY_STORE_kg" = list(values = c(50))
  ),
  constants = list(
    # Syntax von Matthias Spangenberg, die funktioniert!
    # Relative path from the nlogo model file!
    "INPUT_FILE" = "\"Input_Clustertest/input_402.txt\"",
    "WeatherFile" = "\"Input_Clustertest/weather_402.txt\""
  ),
  nseeds = 1
)

# Rewrite default parameters by user defined ----
user_params$variables <- purrr::map(user_params$variables, ~list(values = .x))
params[names(user_params)] <- user_params

remove_quotes <- function(path) {
    # Remove possible "\""
    if (substring(path, 1, 1) == "\"") {
        path = substring(path, 2, nchar(path) - 1)
    }
    return (path)
}

check_and_fix_path <- function(path) {
    path = remove_quotes(path)
    # Check valid path
    stopifnot(file.exists(path))
    # Convert path to absolute
    path = normalizePath(path)
    # Add "\"" around the path
    return (sprintf("\"%s\"", path))
}

# Define original paths without quotes
orig_INPUT_FILE <- remove_quotes(params$constants$INPUT_FILE)
orig_WeatherFile <- remove_quotes(params$constants$WeatherFile)

# Use paths that nlrx understands
params$constants$INPUT_FILE <- check_and_fix_path(params$constants$INPUT_FILE)
params$constants$WeatherFile <- check_and_fix_path(params$constants$WeatherFile)

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

# Use original paths in output
results$INPUT_FILE <- orig_INPUT_FILE
results$WeatherFile <- orig_WeatherFile

# Store results ----
write.table(results, file = params$outpath, sep = ",")
