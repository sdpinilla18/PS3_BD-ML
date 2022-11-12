#------------------------------------------------------------------------------#
# BD&MLfAE, PS3
# 8 de noviembre de 2022
# R version 4.1.2
#
# David Santiago Caraballo Candela,
# Sergio David Pinilla Padilla,
# Juan Diego Valencia Romero,
#------------------------------------------------------------------------------#


## 0. Preparar el entorno

# 0.1 Limpiar el entorno
rm(list=ls()) 
Sys.setlocale("LC_CTYPE", "en_US.UTF-8")

# 0.2 Importar paquetes
require(pacman)
p_load(tidyverse,rio,skimr,sf,leaflet,tmaptools,ggsn,osmdata,viridis,gstat,nngeo,spdep)

## 1. Importar bases de datos

train <- readRDS("train.Rds") 

test <- readRDS("test.Rds") 

geoprop <- rbind(train,test) # Dataframe completo

geoprop1 <- st_as_sf(x=geoprop,coords=c("lon","lat"),crs=4326) # Datos geoespaciales

leaflet() %>% addTiles() %>% addCircleMarkers(data=geoprop1)

#geoprop2 <- st_buffer(x=geoprop1,dist=2000)

#leaflet() %>% addTiles() %>% addCircleMarkers(data=geoprop2)

## 2. Poligonos de los municipios

Bogotá = getbb(place_name = "Bogotá Distrito Capital - Municipio",
               featuretype = "boundary:administrative",
               format_out = "sf_polygon")

leaflet() %>% addTiles() %>% addPolygons(data=Bogotá)


Medellín = getbb(place_name = "Medellín Colombia",
                 featuretype = "boundary:administrative",
                 format_out = "sf_polygon")

Medellín <- Medellín[1,1]

leaflet() %>% addTiles() %>% addPolygons(data=Medellín)

Cali = getbb(place_name = "Cali Colombia",
                 featuretype = "boundary:administrative",
                 format_out = "sf_polygon")

leaflet() %>% addTiles() %>% addPolygons(data=Cali)


## 3. Datos OSM por hogar


# 3.1 Centroids

city <- c("Bog","Med","Cal")
cent_lat <- c(4.6534649, 6.2443382,3.4517923)
cent_lon <- c(-74.0836453,-75.5735530, -76.5324943)

centdf <- data.frame(city,cent_lat,cent_lon)

centgeo <- st_as_sf(x=centdf,coords=c("cent_lon","cent_lat"),crs=4326) # Datos geoespaciales

leaflet() %>% addTiles() %>% addCircleMarkers(data=centgeo)

cent <- list()

cent[[1]] <- filter(centgeo,city=="Bog")
cent[[2]] <- filter(centgeo,city=="Med")
cent[[3]] <- filter(centgeo,city=="Cal")

# 3.2 Manzanas

mnz <- st_read("MNZ/MGN_URB_MANZANA.shp")

mnz <- st_transform(mnz,crs=4326)

mnz <- filter(mnz, COD_MPIO %in% c("05001","11001","76001") )

geoprop1 <- st_join(geoprop1,mnz)

mnz_data <- readRDS("mnzdata_censo_2018.Rds") 

geoprop1 <- left_join(geoprop1,mnz_data,by=c("COD_DANE"="COD_DANE_ANM"))

Bogota_DC = filter(geoprop1, city %in% c("Bogotá D.C"))

Medellin_D = filter(geoprop1, city %in% c("Medellín"))

Cali_D = filter(geoprop1, city %in% c("Cali"))

# 3.3 Distancias

# 3.3.1 Centroids
cent_bog <- filter(centgeo,city=="Bog")
Bogota_DC$dist_cent <- st_distance(x=Bogota_DC,y=cent_bog)

cent_med <- filter(centgeo,city=="Med")
Medellin_D$dist_cent <- st_distance(x=Medellin_D,y=cent_med)

cent_cal <- filter(centgeo,city=="Cal")
Cali_D$dist_cent <- st_distance(x=Cali_D,y=cent_cal)

# 3.3.2 Airports

air <- opq(bbox = getbb("Bogotá Distrito Capital - Municipio")) %>%
  add_osm_feature(key = "aeroway", value = "aerodrome") %>%
  osmdata_sf() %>% .$osm_points
mtxar <- st_distance(x=Bogota_DC,y=air)
Bogota_DC$dist_air <- apply(mtxar,1,min)

air <- opq(bbox = getbb("Medellín Colombia")) %>%
  add_osm_feature(key = "aeroway", value = "aerodrome") %>%
  osmdata_sf() %>% .$osm_points
mtxar <- st_distance(x=Medellin_D,y=air)
Medellin_D$dist_air <- apply(mtxar,1,min)

air <- opq(bbox = getbb("Cali Colombia")) %>%
  add_osm_feature(key = "aeroway", value = "aerodrome") %>%
  osmdata_sf() %>% .$osm_points
mtxar <- st_distance(x=Cali_D,y=air)
Cali_D$dist_air <- apply(mtxar,1,min)

# 3.3.3 Bus stations

bus <- opq(bbox = getbb("Bogotá Distrito Capital - Municipio")) %>%
  add_osm_feature(key = "amenity", value = "bus_station") %>%
  osmdata_sf() %>% .$osm_points
mtxbs <- st_distance(x=Bogota_DC,y=bus)
Bogota_DC$dist_bus <- apply(mtxbs,1,min)

bus <- opq(bbox = getbb("Medellín Colombia")) %>%
  add_osm_feature(key = "amenity", value = "bus_station") %>%
  osmdata_sf() %>% .$osm_points
mtxbs <- st_distance(x=Medellin_D,y=bus)
Medellin_D$dist_bus <- apply(mtxbs,1,min)


bus <- opq(bbox = getbb("Cali Colombia")) %>%
  add_osm_feature(key = "amenity", value = "bus_station") %>%
  osmdata_sf() %>% .$osm_points
mtxbs <- st_distance(x=Cali_D,y=bus)
Cali_D$dist_bus <- apply(mtxbs,1,min)

# 3.3.4 Hospital

hosp <- opq(bbox = getbb("Bogotá Distrito Capital - Municipio")) %>%
  add_osm_feature(key = "amenity", value = "hospital") %>%
  osmdata_sf() %>% .$osm_points
mtxhs <- st_distance(x=Bogota_DC,y=hosp)
Bogota_DC$dist_hosp <- apply(mtxhs,1,min)

hosp <- opq(bbox = getbb("Medellín Colombia")) %>%
  add_osm_feature(key = "amenity", value = "hospital") %>%
  osmdata_sf() %>% .$osm_points
mtxhs <- st_distance(x=Medellin_D,y=hosp)
Medellin_D$dist_hosp <- apply(mtxhs,1,min)

hosp <- opq(bbox = getbb("Cali Colombia")) %>%
  add_osm_feature(key = "amenity", value = "hospital") %>%
  osmdata_sf() %>% .$osm_points
mtxhs <- st_distance(x=Cali_D,y=hosp)
Cali_D$dist_hosp <- apply(mtxhs,1,min)

# 3.3.5 Policia

pol <- opq(bbox = getbb("Bogotá Distrito Capital - Municipio")) %>%
  add_osm_feature(key = "amenity", value = "police") %>%
  osmdata_sf() %>% .$osm_points
mtxpl <- st_distance(x=Bogota_DC,y=pol)
Bogota_DC$dist_pol <- apply(mtxpl,1,min)

pol <- opq(bbox = getbb("Medellín Colombia")) %>%
  add_osm_feature(key = "amenity", value = "police") %>%
  osmdata_sf() %>% .$osm_points
mtxpl <- st_distance(x=Medellin_D,y=pol)
Medellin_D$dist_pol <- apply(mtxpl,1,min)

pol <- opq(bbox = getbb("Cali Colombia")) %>%
  add_osm_feature(key = "amenity", value = "police") %>%
  osmdata_sf() %>% .$osm_points
mtxpl <- st_distance(x=Cali_D,y=pol)
Cali_D$dist_pol <- apply(mtxpl,1,min)

# 3.3.6 Shops

shop1 <- opq(bbox = getbb("Bogotá Distrito Capital - Municipio")) %>%
  add_osm_feature(key = "shop", value = "mall") %>%
  osmdata_sf() %>% .$osm_points
mtxsh1 <- st_distance(x=Bogota_DC,y=shop1)
tdist_sh1 <- apply(mtxsh1,1,min)

shop2 <- opq(bbox = getbb("Bogotá Distrito Capital - Municipio")) %>%
  add_osm_feature(key = "shop", value = "supermarket") %>%
  osmdata_sf() %>% .$osm_points
mtxsh2 <- st_distance(x=Bogota_DC,y=shop2)
tdist_sh2 <- apply(mtxsh2,1,min)

tdist_sh <- list()
for (n in 1:37985){
  tdist_sh[n] = min(tdist_sh1[n],tdist_sh2[n])
}
tdist_sh <- as.data.frame(tdist_sh)
tdist_sh <- t(tdist_sh)
Bogota_DC$dist_shop <- tdist_sh

shop1 <- opq(bbox = getbb("Medellín Colombia")) %>%
  add_osm_feature(key = "shop", value = c("mall","supermarket")) %>%
  osmdata_sf() %>% .$osm_points
mtxsh1 <- st_distance(x=Medellin_D,y=shop1)
Medellin_D$dist_shop <- apply(mtxsh1,1,min)

shop1 <- opq(bbox = getbb("Cali Colombia")) %>%
  add_osm_feature(key = "shop", value = c("mall","supermarket")) %>%
  osmdata_sf() %>% .$osm_points
mtxsh1 <- st_distance(x=Cali_D,y=shop1)
Cali_D$dist_shop <- apply(mtxsh1,1,min)

# 3.3.7 Bar

bar <- opq(bbox = getbb("Bogotá Distrito Capital - Municipio")) %>%
  add_osm_feature(key = "amenity", value = "bar") %>%
  osmdata_sf() %>% .$osm_points
mtxbr <- st_distance(x=Bogota_DC,y=bar)
Bogota_DC$dist_bar <- apply(mtxbr,1,min)

bar <- opq(bbox = getbb("Medellín Colombia")) %>%
  add_osm_feature(key = "amenity", value = "bar") %>%
  osmdata_sf() %>% .$osm_points
mtxbr <- st_distance(x=Medellin_D,y=bar)
Medellin_D$dist_bar <- apply(mtxbr,1,min)

bar <- opq(bbox = getbb("Cali Colombia")) %>%
  add_osm_feature(key = "amenity", value = "bar") %>%
  osmdata_sf() %>% .$osm_points
mtxbr <- st_distance(x=Cali_D,y=bar)
Cali_D$dist_bar <- apply(mtxbr,1,min)

# 3.3.8 University

univ <- opq(bbox = getbb("Bogotá Distrito Capital - Municipio")) %>%
  add_osm_feature(key = "amenity", value = "university") %>%
  osmdata_sf() %>% .$osm_points
mtxun <- st_distance(x=Bogota_DC,y=univ)
Bogota_DC$dist_univ <- apply(mtxun,1,min)

univ <- opq(bbox = getbb("Medellín Colombia")) %>%
  add_osm_feature(key = "amenity", value = "university") %>%
  osmdata_sf() %>% .$osm_points
mtxun <- st_distance(x=Medellin_D,y=univ)
Medellin_D$dist_univ <- apply(mtxun,1,min)

univ <- opq(bbox = getbb("Cali Colombia")) %>%
  add_osm_feature(key = "amenity", value = "university") %>%
  osmdata_sf() %>% .$osm_points
mtxun <- st_distance(x=Cali_D,y=univ)
Cali_D$dist_univ <- apply(mtxun,1,min)

# 3.3.9 Restaurants

rest <- opq(bbox = getbb("Bogotá Distrito Capital - Municipio")) %>%
  add_osm_feature(key = "amenity", value = "restaurant") %>%
  osmdata_sf() %>% .$osm_points
mtxrs <- st_nearest_feature(x=Bogota_DC,y=rest)
tdist_rs <- list()
for (n in 1:37985){
  tdist_rs[n] = st_distance(Bogota_DC$geometry[n],rest[mtxrs[n],88])
}
tdist_rs <- as.data.frame(tdist_rs)
tdist_rs <- t(tdist_rs)
Bogota_DC$dist_rest <- tdist_rs

rest <- opq(bbox = getbb("Medellín Colombia")) %>%
  add_osm_feature(key = "amenity", value = "restaurant") %>%
  osmdata_sf() %>% .$osm_points
mtxrs <- st_distance(x=Medellin_D,y=rest)
Medellin_D$dist_rest <- apply(mtxrs,1,min)

rest <- opq(bbox = getbb("Cali Colombia")) %>%
  add_osm_feature(key = "amenity", value = "restaurant") %>%
  osmdata_sf() %>% .$osm_points
mtxrs <- st_distance(x=Cali_D,y=rest)
Cali_D$dist_rest <- apply(mtxrs,1,min)

# 3.3.9 Schools

scho <- opq(bbox = getbb("Bogotá Distrito Capital - Municipio")) %>%
  add_osm_feature(key = "amenity", value = "school") %>%
  osmdata_sf() %>% .$osm_points
mtxsch <- st_nearest_feature(x=Bogota_DC,y=scho)
tdist_sch <- list()
for (n in 1:37985){
  tdist_sch[n] = st_distance(Bogota_DC$geometry[n],scho[mtxsch[n],48])
}
tdist_sch <- as.data.frame(tdist_sch)
tdist_sch <- t(tdist_sch)
Bogota_DC$dist_scho <- tdist_sch

scho <- opq(bbox = getbb("Medellín Colombia")) %>%
  add_osm_feature(key = "amenity", value = "school") %>%
  osmdata_sf() %>% .$osm_points
mtxsch <- st_distance(x=Medellin_D,y=scho)
Medellin_D$dist_scho <- apply(mtxsch,1,min)

scho <- opq(bbox = getbb("Cali Colombia")) %>%
  add_osm_feature(key = "amenity", value = "school") %>%
  osmdata_sf() %>% .$osm_points
mtxsch <- st_distance(x=Cali_D,y=scho)
Cali_D$dist_scho <- apply(mtxsch,1,min)








# Oldcode
nm = c("Bogotá Distrito Capital - Municipio","Medellín Colombia","Cali Colombia")

for (vl in 1:3){
  vps[[vl]] <- opq(bbox = getbb(nm[vl])) %>%
    add_osm_feature(key = "highway", value=c("trunk","primary","secondary","tertiary")) %>%
    osmdata_sf() %>% .$osm_lines
  
  wat[[vl]] <- opq(bbox = getbb(nm[vl])) %>%
    add_osm_feature(key = "waterway", value=c("river","stream","canal")) %>%
    osmdata_sf() %>% .$osm_lines
  
  park[[vl]] <- opq(bbox = getbb(nm[vl])) %>%
    add_osm_feature(key = "leisure", value = "park") %>%
    osmdata_sf() %>% .$osm_polygons
  
}