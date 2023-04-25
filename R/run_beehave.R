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
  jvmmem = 1024
)

# Set default parameter values ----
params <- list(
  experiment_name = "Exp1",
  repetition = 1,
  tickmetrics = "true",
  idsetup = "setup",
  idgo = "go",
  runtime = 732,
  outpath = file.path("data/output/Result_table.csv"),
  metrics = c(
    "TotalIHbees + TotalForagers",
    "(honeyEnergyStore / ( ENERGY_HONEY_per_g * 1000 ))",
    "PollenStore_g"
  ),
  variables = list(
    "N_INITIAL_BEES" = list(values = c(10000, 10000, 10000)),
    "MAX_HONEY_STORE_kg" = list(values = c(50, 50, 50))
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
params[names(user_params)] <- user_params

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
write.table(results, file = params$outpath, sep = ",")
