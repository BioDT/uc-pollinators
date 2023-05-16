# Load libraries -----
library(jsonlite)

# Single execution -----
params <-
  list(
    outpath = file.path(getwd(), "data/output/Result_table402.csv"),
    metrics = c(
      "TotalIHbees + TotalForagers",
      "(honeyEnergyStore / ( ENERGY_HONEY_per_g * 1000 ))",
      "PollenStore_g"
    ),
    variables = list(
      "N_INITIAL_BEES" = list(values = c(10000, 10000, 10000)),
      "MAX_HONEY_STORE_kg" = list(values = c(50, 50, 50))
    ),
    constants = list("INPUT_FILE" = "\"Input_Clustertest/input_402.txt\"",
                     "WeatherFile" = "\"Input_Clustertest/weather_402.txt\""),
    nseeds = 1
  )

jsonlite::write_json(params,
                     path = "data/single_execution.json")

# HQ execution -----

# params_json <- jsonlite::read_json("data/single_execution.json",
#                                    simplifyVector = TRUE)
# all.equal(params, params_json)

params <-
  list(
    list(
      outpath = file.path(getwd(), "data/output/Result_table402.csv"),
      metrics = c(
        "TotalIHbees + TotalForagers",
        "(honeyEnergyStore / ( ENERGY_HONEY_per_g * 1000 ))",
        "PollenStore_g"
      ),
      variables = list(
        "N_INITIAL_BEES" = list(values = c(10000, 10000, 10000)),
        "MAX_HONEY_STORE_kg" = list(values = c(50, 50, 50))
      ),
      constants = list("INPUT_FILE" = "\"Input_Clustertest/input_402.txt\"",
                       "WeatherFile" = "\"Input_Clustertest/weather_402.txt\""),
      nseeds = 1
    )
    ,
    list(
      outpath = file.path(getwd(), "data/output/Result_table415.csv"),
      metrics = c(
        "TotalIHbees + TotalForagers",
        "(honeyEnergyStore / ( ENERGY_HONEY_per_g * 1000 ))",
        "PollenStore_g"
      ),
      variables = list(
        "N_INITIAL_BEES" = list(values = c(10000, 10000, 10000)),
        "MAX_HONEY_STORE_kg" = list(values = c(50, 50, 50))
      ),
      constants = list("INPUT_FILE" = "\"Input_Clustertest/input_415.txt\"",
                       "WeatherFile" = "\"Input_Clustertest/weather_415.txt\""),
      nseeds = 1
    )
  )

jsonlite::write_json(params,
                     path = "data/hq_execution.json")

