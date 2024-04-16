box::use(
  jsonlite[write_json],
  readr[read_delim, read_csv, col_character, col_double, col_skip],
  purrr[map],
)

#' @export
beehave_prepare_hq_json <- function(
    input_dir = "data/input",
    output_dir = "data/output",
    map = "map.tif",
    lookup_table = "lookup_table.csv",
    locations = "locations.csv",
    parameters = "parameters.csv",
    buffer = 5000L,
    iteration = 1L){

# Prepare file paths ----
input_tif_path <- 
  file.path(input_dir, map)
input_lookup_path <-
  file.path(input_dir, lookup_table)
input_locations_path <-
  file.path(input_dir, locations)
input_parameters_path <- 
  file.path(input_dir, parameters)

# Load locations ----
# We expect the locations CSV to have two columns "lon" and "lat" with "EPSG:4326" - "WGS 84", i.e. GPS coordinates
locations <-
  read_delim(input_locations_path,
                    delim = ",",
                    col_types = list(
                      id = "i",
                      lat = "d",
                      lon = "d"
                    ))

parameters <- 
  read_csv(
    file = input_parameters_path,
    col_types = list(
      Parameter = col_character(),
      Value = col_double(),
      `Default.Value` = col_skip()
    )
  )

parameters_list <- parameters$Value |>
  map(~list(.x))
names(parameters_list) <- parameters$Parameter

# Create output JSON ----
# This part is used to prepare input and weather files for Beehave computed with HyperQueue

output_list <- apply(
  locations,
  MARGIN = 1,
  FUN = function(x) {
    list(
      id = x[["id"]],
      lat = x[["lat"]],
      lon = x[["lon"]],
      buffer_size = buffer,
      location_path = file.path(input_dir, "locations"),
      input_tif_path = input_tif_path,
      nectar_pollen_lookup_path = input_lookup_path
    )
  }
)

write_json(output_list,
           path = file.path(input_dir, "locations.json"))

# Netlogo run JSON preparation ----
# This part is used to do actual computation of the Beehave simulation with HyperQueue
# For first run this will be static on parameters and will change the input files names

netlogo_list <- apply(
  locations,
  MARGIN = 1,
  FUN = function(x) {
    list(
      outpath = file.path(
        output_dir,
        paste0("output_id", x[[1]], "_iter", iteration, ".csv")
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
          input_dir,
          "/locations",
          "/input_",
          x[[1]],
          ".txt\""
        ),
        "WeatherFile" = paste0(
          "\"",
          input_dir,
          "/locations",
          "/weather_",
          x[[1]],
          ".txt\""
        )
      ),
      nseeds = 1L
    )
  }
)

write_json(netlogo_list,
           path = file.path(input_dir, "netlogo.json"))

}
