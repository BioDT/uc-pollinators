# Import functions ----
box::use(
  optparse[OptionParser, add_option, parse_args],
  jsonlite[parse_json],
  purrr[map],
  stringr[str_split],
  stats[na.omit],
  dplyr[mutate],
  readr[read_file],
)

box::use(
  R/step3_run/nl_experiment[run_simulation]
)

# Define command line arguments ----

parser <- OptionParser() |>
  add_option(c("-u", "--user-parameters"),
             type = "character",
             help = "JSON containing parameters for the beehave simulation. See run_beehave_3.R for structure.") |>
  add_option(
    c("-v", "--netlogo-jar-path"),
    type = "character",
    default = "/NetLogo 6.3.0/app/netlogo-6.3.0.jar",
    help = "Netlogo version [default %default]"
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
# inputs$netlogo_version <- "6.4.0"
# inputs$netlogo_home <- "/Users/martinovic/data/BioDT/beehave/NetLogo 6.4.0/"
# Sys.setenv(JAVA_HOME="/Users/martinovic/data/BioDT/beehave/jdk-17.0.6.jdk/Contents/Home/")
# inputs$model_path <- "/Users/martinovic/data/test/2024-04-23_11-48-01_7BdxFcSF/beekeeper/2024-04-23_11-48-19/Beehave_BeeMapp2015_Netlogo6version_PolygonAggregation.nlogo"
# user_params <- jsonlite::read_json(path = "/Users/martinovic/data/test/2024-04-23_11-48-01_7BdxFcSF/beekeeper/2024-04-23_11-48-19/netlogo.json", simplifyVector = TRUE)
# user_params$constants$WeatherFile[[1]] <- "\"/Users/martinovic/data/test/2024-04-23_11-48-01_7BdxFcSF/beekeeper/2024-04-23_11-48-19/locations/weather_1.txt\""
# user_params$constants$INPUT_FILE[[1]] <- "\"/Users/martinovic/data/test/2024-04-23_11-48-01_7BdxFcSF/beekeeper/2024-04-23_11-48-19/locations/input_1.txt\""
# user_params$outpath <- "/Users/martinovic/data/test/2024-04-23_11-48-01_7BdxFcSF/beekeeper/2024-04-23_11-48-19/output"

if (!is.null(user_params$variables$HoneyHarvesting)) {
  user_params$variables$HoneyHarvesting <- ifelse(user_params$variables$HoneyHarvesting == 0, "false", "true")
}
if (!is.null(user_params$variables$VarroaTreatment)) {
  user_params$variables$VarroaTreatment <- ifelse(user_params$variables$VarroaTreatment == 0, "false", "true")
}
if (!is.null(user_params$variables$DroneBroodRemoval)) {
  user_params$variables$DroneBroodRemoval <- ifelse(user_params$variables$DroneBroodRemoval == 0, "false", "true")
}


# Rewrite default parameters by user defined ----
# user_params$variables <- map(user_params$variables, ~list(values = .x |> unlist() |> unname()))

input_file <- gsub('^.|.$', '', user_params$variables$INPUT_FILE)
weather_file <- gsub(
  '^.|.$', '', user_params$variables$WeatherFile
)
stopifnot(file.exists(input_file))
stopifnot(file.exists(weather_file))
# print("passed_file_check")

# Load weather data ----
weather <- read_file(weather_file) |>
  str_split(" ",
            simplify = TRUE
  ) |>
  as.integer() |>
  na.omit()

weather <- rep(weather, 10)
# Run experiment ----
results <- run_simulation(
  inputs$netlogo_jar_path,
  inputs$model_path,
  user_params$outpath,
  user_params
)

start_date <- user_params$start_day[[1]] |>
  as.Date()

results <- results |>
  mutate(weather = weather[1:nrow(results)],
         date = seq(from = start_date,
                    to = start_date + user_params$sim_days[[1]],
                    by = "day"))

# Store results ----
write.table(results,
            file = user_params$outpath,
            sep = ",",
            row.names = FALSE)
