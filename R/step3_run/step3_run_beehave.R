# Import functions ----
box::use(
  optparse[OptionParser, add_option, parse_args],
  nlrx[nl, experiment, simdesign_distinct, run_nl_all],
  jsonlite[parse_json],
  purrr[map],
  stringr[str_split],
  stats[na.omit],
  dplyr[mutate],
  readr[read_file],
)

# Define command line arguments ----

parser <- OptionParser() |>
  add_option(c("-p", "--user-parameters"),
                       type = "character",
                       help = "JSON containing parameters for the beehave simulation. See run_beehave_3.R for structure.") |>
  add_option(
    c("-v", "--netlogo-version"),
    type = "character",
    default = "6.3.0",
    help = "Netlogo version [default %default]"
  ) |>
  add_option(
    c("-n", "--netlogo-home"),
    type = "character",
    action = "store",
    default = "/NetLogo",
    help = "Netlogo home path [default %default]"
  ) |>
  add_option(
    c("-m", "--model-path"),
    type = "character",
    action = "store",
    default = "data/Beehave_BeeMapp2015_Netlogo6version_PolygonAggregation.nlogo",
    help = "Path to Beehave model file [default %default]"
  )

inputs <- parse_args(
  parser,
  positional_arguments = TRUE,
  convert_hyphens_to_underscores = TRUE
)$options

# Parse input parameters
user_params <- inputs$user_parameters |>
  parse_json(simplifyVector = TRUE)

# inputs <- list()
# inputs$netlogo_version <- "6.3.0"
# inputs$netlogo_home <- "~/data/BioDT/beehave/NetLogo 6.3.0/"
# Sys.setenv(JAVA_HOME="~/data/BioDT/beehave/jdk-17.0.6.jdk/Contents/Home")
# inputs$model_path <- "~/git/biodt-prod/shared/v2Ye7Nqwr/Beehave_BeeMapp2015_Netlogo6version_PolygonAggregation.nlogo"
# user_params <- jsonlite::read_json(path = "/Users/martinovic/git/biodt-prod/shared/v2Ye7Nqwr/netlogo.json", simplifyVector = TRUE)

if (!is.null(user_params$variables$HoneyHarvesting)) {
  user_params$variables$HoneyHarvesting <- user_params$variables$HoneyHarvesting |> as.logical()
}
if (!is.null(user_params$variables$VarroaTreatment)) {
  user_params$variables$VarroaTreatment <- user_params$variables$VarroaTreatment |> as.logical()
}
if (!is.null(user_params$variables$DroneBroodRemoval)) {
  user_params$variables$DroneBroodRemoval <- user_params$variables$DroneBroodRemoval |> as.logical()
}

# Create nl object which hold info on NetLogo version and model path.
nl <- nl(
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
user_params$variables <- map(user_params$variables, ~list(values = .x |> unlist() |> unname()))
params[names(user_params)] <- user_params

params$variables$HoneyHarvesting <- NULL
params$variables$VarroaTreatment <- NULL
params$variables$DroneBroodRemoval <- NULL

input_file <- gsub('^.|.$', '', params$constants$INPUT_FILE)
weather_file <- gsub(
  '^.|.$', '', params$constants$WeatherFile
)
stopifnot(file.exists(input_file))
stopifnot(file.exists(weather_file))
# print("passed_file_check")
# Define experiment ----
nl@experiment <- experiment(
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
nl@simdesign <- simdesign_distinct(nl = nl,
                                   nseeds = params$nseeds)

# Load weather data ----
weather <- read_file(weather_file) |>
  str_split(" ",
            simplify = TRUE
  ) |>
  as.integer() |>
  na.omit()

print(weather)

weather <- rep(weather, 10)
print(weather)
# Run experiment ----
results <- run_nl_all(nl = nl)

results <- results |>
  mutate(weather = weather[1:nrow(results)])

# Store results ----
write.table(results,
            file = params$outpath,
            sep = ",",
            row.names = FALSE)
