###### R - helper functions to create input (resources) files to run the BEEHAVE model
# main contributor Anna Wendt, University of Freiburg
# modifications have been done by Jürgen Groeneveld, Tomas Martinovic, Tuomas Rossi 
# the honeybee pDT has benefited from the work of the honeybee pDT team

# Import functions ----
box::use(
  terra[crs, buffer, crop, classify, cats, set.values, cells, vect, voronoi],
  sf[st_as_sf, st_sample, st_sf, st_coordinates, st_is_valid, st_make_valid, st_intersection],
  dplyr[mutate, filter, select, left_join],
  stats[kmeans],
)

#' @export
extract_list <- function(x) {
  x[[1]]
}

# Function to split polygons using regular point clusters and voronoi-polygons
#' @export
SplitPolygonsEqual <- function(polygon, polygon_size, density = 1000, RefCRS) {
  # split polygon in smaller polygons with +/- equal size
  # using regular points and voronoi polygons
  # with size indicating the target size of the polygons
  # and density altering the point density generated per polygon

  # transform spatvector to sf-polygon
  polygon <- st_as_sf(polygon, crs = RefCRS)

  # calculate number of points
  nPoints <- floor(polygon$size_sqm/density)
  # and create regular points covering polygon
  points <- st_sample(polygon, size = nPoints, type = "regular") |>
    st_sf()

  # calculate amounts of polygons to be split into
  nPolys <- ceiling(polygon$size_sqm/polygon_size)
  # create clusters using kmeans
  pointClusters <- st_coordinates(points) |>
    kmeans(nPolys)

  # extract centroids for voronoi polygons
  centroids <- data.frame(pointClusters$centers) |>
    vect(geom = c("X", "Y"), crs = RefCRS)

  # create voronoi polygons
  voronoiPoly <- voronoi(centroids, polygon) |>
    st_as_sf(crs = RefCRS)

  # check validity of polygon and correct it if needed
  if (st_is_valid(polygon) == FALSE) {
    polygon <- st_make_valid(polygon)
  }

  # clip voronoi polygons to input polygon
  polyFinal <- st_intersection(polygon, voronoiPoly) |>
    vect()

  return(polyFinal)
}

# Function to create spatial variability in flowering of grassland polygons
#' @export
SpatialVaryingInput <- function(input, monthlyProb) {
  # alter flowering time of grassland in the BeeHave input-file
  # so that each grassland Patch is only flowering one month
  # "monthlyProb" indicates the probability of flowering per month
  # with numbers between 0 and 1 giving the probability of flowering
  # of each month (length = 12)

  # extract Patch IDs of Grassland
  grasslandIDs <- input |>
    filter(PatchType == "Grassland") |>
    select("id") |>
    unique()

  # generate random numbers indicating at which months Patch is flowering
  # with given probabilities per month
  FloweringLookup <-
    data.frame(grasslandIDs,
      flowerMonth = sample(1:12, length(grasslandIDs),
        prob = monthlyProb,
        replace = TRUE
      )
    )

  # join month of flowering to input file and calculate month from date
  newInput <- left_join(input, FloweringLookup,
    by = "id"
  ) |>
    mutate(month = month(as.Date(day - 1, origin = "2016-01-01")))

  #
  newInput <- newInput |>
    mutate(flowering = ifelse(flowerMonth == month, TRUE, FALSE)) |>
    mutate(
      quantityNectar_l = ifelse(flowering == TRUE, quantityNectar_l, 0),
      quantityPollen_g = ifelse(flowering == TRUE, quantityPollen_g, 0)
    ) |>
    select(-c(month, flowerMonth, flowering))

  return(newInput)
}
