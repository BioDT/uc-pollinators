###### R - script to create input (resources and weather) files to run the BEEHAVE model
# main contributor Anna Wendt, University of Freiburg
# contributor of an earlier version of the WeatherDataInput() function Okan Özsoy
# modifications have been done by Jürgen Groeneveld, Tomas Martinovic, Tuomas Rossi
# the honeybee pDT has benefited from the work of the honeybee pDT team

# Import functions ----
box::use(
  terra[crs, buffer, crop, classify, cats, set.values, cells, as.polygons, disagg, expanse, crds, distance, centroids, values, `values<-`],
  dplyr[mutate, filter, pull, left_join, rename, select, slice, n],
)

box::use(
  R/step2_input/fct_resources[extract_list, SplitPolygonsEqual, SpatialVaryingInput],
)

#### BeeHave Input-File Generator #####
# Function to generate Input Files for BEEHAVE-Model
# based on the landscape classification map by Preidl et al. (2020)
#
# Input of function: Raster Image as SpatRaster and
#                    Location of Beehave as SpatVector
#                    Nectar and Pollen Data
# (using package terra, sf, dplyr, lubridate and rdwd)

#' @export
beehave_input <- function(input_map,
                          bee_location,
                          lookup_table,
                          polygon_size = 200000,
                          buffer_size = 3000,
                          beehave_levels = c(
                            "Maize",
                            "Legumes",
                            "Rapeseed",
                            "Strawberries",
                            "Stone Fruits",
                            "Vines",
                            "Asparagus",
                            "Grassland"
                          )) {
  ## 01 clip map to location and relevant crop types ##
  # extract Coordinate Reference System
  RefCRS <- crs(input_map, parse = FALSE)

  # create buffer around Beehave Locations...
  clip_buffer <- buffer(bee_location, width = buffer_size)

  # ... and clip raster to buffer
  location_area <- crop(input_map, clip_buffer)

  # to select only bee-relevant landscape types, remaining values are set to NA
  # first extract Values of bee-relevant landscapes
  bee_landscapes <- location_area |>
    cats() |>
    extract_list() |>
    filter(category %in% beehave_levels) |>
    pull(value)

  # Change values that are not beehave_levels to NA, this keeps levels unlike reclassify used previously
  set.values(location_area, cells(location_area, setdiff(0:24, bee_landscapes)) |> unlist(), NA)


  # # create a dataframe for reclassification which sets all other landscapes to NA
  # lookUpValues <- data.frame(from = 0:24) %>%
  #   mutate(to = ifelse(from %in% bee_landscapes, from, NA))
  #
  # # reclassify values in clipped raster image
  # location_area <- classify(location_area, lookUpValues)
  #
  # # change values to correct categories as displayed in input map
  # # lookUpCategories <- data.frame(
  # #   value = 0:24,
  # #   category = levels(input_map)[[1]])
  #
  # lookUpCategories <- data.frame(levels(input_map)[[1]])
  #
  # # extract values present at location (in case not all values are present)
  # valuesLocation <- unique(values(location_area))
  #
  # # overwrite levels in clipped raster image to PatchType Name
  # levels(location_area) <- lookUpCategories[which(lookUpCategories$value %in%
  #                                                  valuesLocation),]

  ## 02 create polygons and add first attributes ##
  # transform raster to polygons and disaggregate into multipolygon object
  location_area_poly <- as.polygons(location_area) |>
    disagg()

  # add attributes (id, area) to polygons
  values(location_area_poly) <- values(location_area_poly) |>
    mutate(id = 1:n(), .before = category) |>
    mutate(size_sqm = expanse(location_area_poly)) |>
    rename(PatchType = category)

  ## 03 split big polygons into multiple smaller ones ##
  # select polygons bigger than threshold (default: > 20ha)
  PolySelection <- subset(
    location_area_poly,
    location_area_poly$size_sqm > polygon_size
  )

  # exclude polygons from original vector
  # to be able to combine it later again with split up polygons
  location_area_poly_sub <- subset(
    location_area_poly,
    location_area_poly$size_sqm < polygon_size
  )

  # loop over polygons to split them up separately
  for (i in PolySelection$id) {
    # first select polygon
    split_polygon <- PolySelection |>
      subset(PolySelection$id == i)

    # use helper function to split polygons
    split_polygon <- SplitPolygonsEqual(split_polygon,
      polygon_size = polygon_size,
      RefCRS = RefCRS
    )

    # rejoin split up polygons to the rest
    location_area_poly_sub <- rbind(location_area_poly_sub, split_polygon)
  }

  # overwrite polygons with new splitted polygons
  location_area_poly <- location_area_poly_sub

  ## 04 update geographical attributes
  coordsPolys <- crds(centroids(location_area_poly))
  coordsBees <- crds(bee_location)

  # add running id, oldPatchID, calculate polygon size and distance to beehave
  # calculate centroid location with beehave as reference = (0,0)
  LocationAttributes <- values(location_area_poly) |>
    mutate(
      id = 1:n() - 1,
      oldPatchID = id, .before = PatchType,
      size_sqm = round(expanse(location_area_poly)),
      distance_m = round(as.vector(distance(bee_location, location_area_poly))),
      xcor = round(coordsPolys[, 1] - coordsBees[, 1]),
      ycor = round(coordsPolys[, 2] - coordsBees[, 2])
    ) |>
    select(c("id", "oldPatchID", "PatchType", "distance_m", "xcor", "ycor", "size_sqm"))

  values(location_area_poly) <- LocationAttributes

  ## 05 add nectar and pollen information and create input file

  # transform geographic information to daily format
  # and add nectar and pollen information
  InputTable <- data.frame(LocationAttributes) |>
    slice(rep(1:n(), each = 365)) |>
    mutate(day = rep(1:365, nrow(LocationAttributes)), .before = id) |>
    left_join(lookup_table[, -c(7:8)], by = "PatchType") |>
    # calculate detection probability and set modelled detection prob. to 0
    mutate(
      calculatedDetectionProb_per_trip = exp(-0.00073 * distance_m),
      modelledDetectionProb_per_trip = 0, .before = nectarGathering_s
    ) |>
    # calculate nectar and pollen quantity according to patch size
    # set distance of polygon containing beehave to 0.1 meter
    mutate(
      quantityNectar_l = quantityNectar_l * size_sqm,
      quantityPollen_g = quantityPollen_g * size_sqm,
      distance_m = ifelse(distance_m == 0, 0.1, distance_m)
    )

  # reduce nectar and pollen availability to flowering days
  # with flowering information provided in lookup_table
  for (i in 1:nrow(lookup_table)) {
    flowerStart <- lookup_table$flowerStart[i]
    flowerEnd <- lookup_table$flowerEnd[i]
    Patch <- lookup_table$PatchType[i]

    InputTable[which(InputTable$PatchType == Patch), ] <-
      InputTable[which(InputTable$PatchType == Patch), ] |>
      mutate(
        quantityNectar_l = ifelse(day >= flowerStart & day <= flowerEnd,
          quantityNectar_l, 0
        ),
        quantityPollen_g = ifelse(day >= flowerStart & day <= flowerEnd,
          quantityPollen_g, 0
        )
      )
  }
  
  # InputTable <- InputTable |>
  #   filter(distance_m < buffer_size )
  # return both Input File and Polygons
  return(list(InputTable, location_area_poly))
}


##### modification of the input file allowing to discriminate the background resources of grassland and resources during summer
# therefore there is GrasslandSeason type in the look up table now

#' @export
modify_input_file <- function(input, lookup_table) {
  temp_start <- lookup_table[which(lookup_table$PatchType == "GrasslandSeason"), 7]
  temp_end <- lookup_table[which(lookup_table$PatchType == "GrasslandSeason"), 8]
  
  if (length(temp_start) == 0 | length(temp_end) == 0) {
    return(input)
  }
  
  temp_old_pollen <- lookup_table[which(lookup_table$PatchType == "Grassland"), 2]
  temp_season_pollen <- lookup_table[which(lookup_table$PatchType == "GrasslandSeason"), 2]
  
  index <- which(input$PatchType == "Grassland" & input$day > temp_start & input$day < temp_end)
  input[index, ]$quantityPollen_g <- input[index, ]$quantityPollen_g/temp_old_pollen * temp_season_pollen
  
  temp_old_nectar <- lookup_table[which(lookup_table$PatchType == "Grassland"), 4]
  temp_season_nectar <- lookup_table[which(lookup_table$PatchType == "GrasslandSeason"), 4]
  
  input[index, ]$quantityNectar_l <- input[index, ]$quantityNectar_l/temp_old_nectar * temp_season_nectar
  
  return(input)
}
