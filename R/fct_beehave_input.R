###### R - script to create input (resources and weather) files to run the BEEHAVE model
# main contributor Anna Wendt, University of Freiburg
# contributor of an earlier version of the WeatherDataInput() function Okan Özsoy
# modifications have been done by Jürgen Groeneveld, Tomas Martinovic, Tuomas Rossi 
# the pollination pDT has benefitted from the work of the pollination pDT team


# Libraries ----
library(terra)
library(sf)
library(dplyr)
library(lubridate)
library(rdwd)

#### BeeHave Input-File Generator #####
# Function to generate Input Files for BEEHAVE-Model
# based on the landscape classification map by Preidl et al. (2020)
#
# Input of function: Raster Image as SpatRaster and 
#                    Location of Beehave as SpatVector 
#                    Nectar and Pollen Data
# (using package terra, sf, dplyr, lubridate and rdwd)

BeehaveInput <- function(LSCMap, BeeLocation, NPData, PolygonSize=200000, buffer_size = 5000){
  
  ## 01 clip map to location and relevant crop types ##
  # extract Coordinate Reference System
  RefCRS <- crs(LSCMap, parse = FALSE)
  
  # create buffer around Beehave Locations...
  clipBuffer <- buffer(BeeLocation, width = buffer_size)
  
  # ... and clip raster to buffer
  LocationArea <- crop(LSCMap, clipBuffer)
  
  
  # to select only bee-relevant landscape types, remaining values are reclassified to NA
  # first extract Values of bee-relevant landscapes
  BeeLandscapes <- c(8, 9, 10, 14, 15, 16, 18, 19)
  
  # create a dataframe for reclassification which sets all other landscapes to NA
  lookUpValues <- data.frame(from = 0:24) %>% 
    mutate(to = ifelse(from %in% BeeLandscapes, from, NA))
  
  # reclassify values in clipped raster image
  LocationArea <- classify(LocationArea, lookUpValues)
  
  # change values to correct categories as displayed in input map
  # lookUpCategories <- data.frame(
  #   value = 0:24, 
  #   category = levels(LSCMap)[[1]])
  
  lookUpCategories <- data.frame(levels(LSCMap)[[1]])
  
  # extract values present at location (in case not all values are present)
  valuesLocation <- unique(values(LocationArea))
  
  # overwrite levels in clipped raster image to PatchType Name
  levels(LocationArea) <- lookUpCategories[which(lookUpCategories$value %in% 
                                                   valuesLocation),]
  
  ## 02 create polygons and add first attributes ##
  # transform raster to polygons and disaggregate into multipolygon object
  LocationAreaPoly <- as.polygons(LocationArea) %>% 
    disagg()
  
  # add attributes (id, area) to polygons
  values(LocationAreaPoly) <- values(LocationAreaPoly) %>%  
    mutate(id = 1:nrow(.), .before = category) %>% 
    mutate(size_sqm = expanse(LocationAreaPoly)) %>% 
    rename(PatchType = category)
  
  ## 03 split big polygons into multiple smaller ones ##
  # select polygons bigger than threshold (default: > 20ha)
  PolySelection <- subset(LocationAreaPoly, 
                          LocationAreaPoly$size_sqm > PolygonSize)
  
  # exclude polygons from original vector
  # to be able to combine it later again with split up polygons
  LocationAreaPolySub <- subset(LocationAreaPoly, 
                                LocationAreaPoly$size_sqm < PolygonSize)
  
  # loop over polygons to split them up separately
  for (i in PolySelection$id){
    
    # first select polygon
    splitPolygon <- PolySelection %>% 
      subset(., PolySelection$id == i)
    
    # use helper function to split polygons
    splitPolygon <- SplitPolygonsEqual(splitPolygon, 
                                       size = PolygonSize,
                                       CRS = RefCRS)
    
    # rejoin split up polygons to the rest 
    LocationAreaPolySub <- rbind(LocationAreaPolySub, splitPolygon)
  }
  
  # overwrite polygons with new splitted polygons
  LocationAreaPoly <- LocationAreaPolySub
  
  ## 04 update geographical attributes
  coordsPolys <- crds(centroids(LocationAreaPoly))
  coordsBees <- crds(BeeLocation)
  
  # add running id, oldPtachID, calculate polygon size and distance to beehave
  # calculate centroid location with beehave as reference = (0,0)
  LocationAttributes <- values(LocationAreaPoly) %>% 
    mutate(id = 1:nrow(.)-1,
           oldPatchID = id, .before = PatchType,
           size_sqm = round(expanse(LocationAreaPoly)),
           distance_m = round(as.vector(distance(BeeLocation, LocationAreaPoly))),
           xcor = round(coordsPolys[,1] - coordsBees[,1]),
           ycor = round(coordsPolys[,2] - coordsBees[,2])) %>% 
    select(c("id", "oldPatchID", "PatchType", "distance_m", "xcor", "ycor", "size_sqm"))
  
  values(LocationAreaPoly) <- LocationAttributes
  
  ## 05 add nectar and pollen information and create input file
  
  # transform geographic information to daily format
  # and add nectar and pollen information
  InputTable <- data.frame(LocationAttributes) %>% 
    slice(rep(1:n(), each = 365)) %>% 
    mutate(day = rep(1:365, nrow(LocationAttributes)), .before = id) %>% 
    left_join(., NPData[,-c(7:8)], by = "PatchType") %>% 
    
    # calculate detection probability and set modelled detection prob. to 0
    mutate(calculatedDetectionProb_per_trip = exp(-0.00073 * distance_m),
           modelledDetectionProb_per_trip = 0, .before = nectarGathering_s) %>% 
    
    # calculate nectar and pollen quantity according to patch size
    # set distance of polygon containing beehave to 0.1 meter
    mutate(quantityNectar_l = quantityNectar_l * size_sqm,
           quantityPollen_g = quantityPollen_g * size_sqm,
           distance_m = ifelse(distance_m == 0, 0.1, distance_m)) 
  
  # reduce nectar and pollen availability to flowering days
  # with flowering information provided in NPData
  for (i in 1:nrow(NPData)) {
    flowerStart <- NPData$flowerStart[i]
    flowerEnd <- NPData$flowerEnd[i]
    Patch <- NPData$PatchType[i]
    
    InputTable[which(InputTable$PatchType == Patch),] <- 
      InputTable[which(InputTable$PatchType == Patch),] %>% 
      mutate(quantityNectar_l = ifelse(day >= flowerStart & day <= flowerEnd,
                                       quantityNectar_l, 0),
             quantityPollen_g = ifelse(day >= flowerStart & day <= flowerEnd,
                                       quantityPollen_g, 0))
  }
  
  # return both Input File and Polygons
  return(list(InputTable, LocationAreaPoly))
}


#### HELPER FUNCTIONS #####
# Function to split polygons using regular point clusters and voronoi-polygons
SplitPolygonsEqual <- function(polygon, size, density = 1000, CRS){
  # split polygon in smaller polygons with +/- equal size
  # using regular points and voronoi polygons
  # with size indicating the target size of the polygons
  # and density altering the point density generated per polygon
  
  #transform spatvector to sf-polygon
  polygon <- st_as_sf(polygon, crs = CRS)
  
  # calculate number of points 
  nPoints <- floor(polygon$size_sqm / density)
  # and create regular points covering polygon
  points <- st_sample(polygon, size = nPoints, type = "regular") %>% 
    st_sf()
  
  # calculate amounts of polygons to be split into
  nPolys <- ceiling(polygon$size_sqm / size)
  # create clusters using kmeans
  pointClusters <- st_coordinates(points) %>%  
    kmeans(., nPolys)
  
  # extract centroids for voronoi polygons
  centroids <- data.frame(pointClusters$centers) %>% 
    vect(., geom = c("X", "Y"), crs = CRS)
  
  # create voronoi polygons
  voronoiPoly <- voronoi(centroids, polygon) %>% 
    st_as_sf(., crs = RefCRS) 
  
  # check validity of polygon and correct it if needed
  if (st_is_valid(polygon) == FALSE) {
    polygon <- st_make_valid(polygon)
  }
  
  # clip voronoi polygons to input polygon
  polyFinal <- st_intersection(polygon, voronoiPoly) %>% 
    vect()
  
  return(polyFinal)
}

# Function to create spatial variability in flowering of grassland polygons
SpatialVaryingInput <- function(input, monthlyProb){
  # alter flowering time of grassland in the BeeHave input-file
  # so that each grassland Patch is only flowering one month
  # "monthlyProb" indicates the probability of flowering per month
  # with numbers between 0 and 1 giving the probability of flowering
  # of each month (length = 12)
  
  # extract Patch IDs of Grassland
  grasslandIDs <- input %>% 
    filter(PatchType == "Grassland") %>% 
    select("id") %>% 
    unique()
  
  # generate random numbers indicating at which months Patch is flowering
  # with given probabilities per month
  FloweringLookup <-
    data.frame(grasslandIDs,
               flowerMonth = sample(1:12, length(grasslandIDs),
                                    prob = monthlyProb,
                                    replace = TRUE))
  
  # join month of flowering to input file and calculate month from date
  newInput <- left_join(input, FloweringLookup, 
                        by = "id") %>% 
    mutate(month = month(as.Date(day-1, origin = "2016-01-01")))
  
  # 
  newInput <- newInput %>% 
    mutate(flowering = ifelse(flowerMonth == month, TRUE, FALSE)) %>% 
    mutate(quantityNectar_l = ifelse(flowering == TRUE, quantityNectar_l, 0),
           quantityPollen_g = ifelse(flowering == TRUE, quantityPollen_g, 0)) %>% 
    select(-c(month, flowerMonth, flowering))
  
  return(newInput)
}

# Function to create a weatherinput file for the beehave model
WeatherDataInput <- function(input){
  
  # transform input coordinates to degrees
  TrachtnetConv <- project(input,"epsg:4326")
  Coordinates <- as.data.frame(crds(TrachtnetConv))
  
  # Read the station data
  WeatherStations <- nearbyStations(
    Coordinates$y, 
    Coordinates$x, 
    radius = 50,
    res="daily",var="kl",per="historical",mindate="2016-12-31") %>%
    # select only stations that started measuring before 2016
    filter(von_datum < as.Date("2016-01-01", "%Y-%m-%d")) 
  
  # check through the stations for NA values in data
  for (i in 1:nrow(WeatherStations)){
    file <- dataDWD(WeatherStations$url[i], varnames = TRUE, quiet= TRUE)
    
    # select only data from 2016 only
    clim_2016 <- filter(file, format(file$MESS_DATUM, "%Y") == 2016)
    
    
    # breaks when file with no NAs in SDK found
    if (anyNA(clim_2016$SDK.Sonnenscheindauer) == FALSE & length(clim_2016$SDK.Sonnenscheindauer) > 0) break 
    
    # if all stations contain NA values give warning
    if (i == length(WeatherStations$Stations_id)){
      warning(paste("Final selected weather station includes NA values. No stations found without any NA within 50km distance. Station ID:", WeatherStations$Stations_id[i]))
    } 
  }
  
  # create the weather input file
  WeatherData = data.frame("Station_id" = rep(WeatherStations$Stations_id[i]),
                           "Day" = 1:365,
                           "T_max" = clim_2016$TXK.Lufttemperatur_Max[1:365],
                           "Sun_hours" = clim_2016$SDK.Sonnenscheindauer[1:365]) %>% 
    # only sun hours are used, when Temp is above 15°C
    mutate(Sun_hours = ifelse(T_max < 15, 0, Sun_hours))
  
  # create vector for BEEHAVE weather input with sunshine hours
  WeatherFile <- paste("[", paste(WeatherData$Sun_hours, collapse = " "), "]")
  
  return(list(WeatherData, WeatherFile))
}



##### modification of the input file allowing to discriminate the background resources of grassland and resources during summer
# therefore there is GrasslandSeason type in the look up table now

modify_Inputfile <- function(input, NPData){
  
  temp_start <- NPData[which(NPData$PatchType == "GrasslandSeason"),7]
  temp_end <- NPData[which(NPData$PatchType == "GrasslandSeason"),8]
  
  if (length(temp_start) == 0 | length(temp_end) == 0) {
    return(input)
  }
  
  temp_old_pollen <- NPData[which(NPData$PatchType == "Grassland"),2]
  temp_season_pollen <- NPData[which(NPData$PatchType == "GrasslandSeason"),2]
  
  index <- which(input$PatchType == "Grassland" & input$day > temp_start & input$day < temp_end) 
  input[index,]$quantityPollen_g <- input[index,]$quantityPollen_g / temp_old_pollen * temp_season_pollen
  
  temp_old_nectar <- NPData[which(NPData$PatchType == "Grassland"),4]
  temp_season_nectar <- NPData[which(NPData$PatchType == "GrasslandSeason"),4]
  
  input[index,]$quantityNectar_l <- input[index,]$quantityNectar_l / temp_old_nectar * temp_season_nectar
  
  return(input)
}

