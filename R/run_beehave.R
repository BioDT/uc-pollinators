# Load libraries -----
library(nlrx)

# Set JAVA and NetLogo paths ----
# To be hardcoded at given infrastructure
Sys.setenv(JAVA_HOME = "/Users/martinovic/beehave/jdk-17.0.6.jdk/Contents/Home/")
netlogopath <- file.path("/Users/martinovic/beehave/NetLogo 6.2.0")
modelpath <-
  file.path(getwd(),
            "data/Beehave_BeeMapp2015_Netlogo6version_PolygonAggregation.nlogo")

# Create nl object which hold info on NetLogo version and model path.
nl <- nl(
  nlversion = "6.2.0",
  nlpath = netlogopath,
  modelpath = modelpath,
  jvmmem = 1024
)

# Set default parameter values ----
params <- list(
  outpath = file.path(getwd(), "data/output/Result_table.csv"),
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

# Prepare input parameters ----
# user_params <- commandArgs(trailingOnly = TRUE) |>
#   read_json(simplifyVector = TRUE)

# Rewrite default parameters by user defined ----
# params[names(user_params)] <- user_params

# Define experiment ----
nl@experiment <- experiment(
  expname = "Test1",
  outpath = params$outpath,
  repetition = 4,
  tickmetrics = "true",
  idsetup = "setup",
  idgo = "go",
  runtime = 732,
  variables = params$variables,
  constants = params$constants,
  metrics = params$metrics
)

# Experiment design ----
nl@simdesign <- simdesign_distinct(nl = nl,
                                   nseeds = params$nseeds)

# Run experiment ----
results <- run_nl_all(nl = nl)

# Store results ----
write.table(results, file = params$outpath, sep = ",")
