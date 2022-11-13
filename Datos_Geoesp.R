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

# 3.3.10 Schools

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


# 3.3.11 Parks

park <- opq(bbox = getbb("Bogotá Distrito Capital - Municipio")) %>%
  add_osm_feature(key = "leisure", value = "park") %>%
  osmdata_sf() %>% .$osm_polygons
mtxpk <- st_distance(x=Bogota_DC,y=park)
Bogota_DC$dist_park <- apply(mtxpk,1,mean)

park <- opq(bbox = getbb("Medellín Colombia")) %>%
  add_osm_feature(key = "leisure", value = "park") %>%
  osmdata_sf() %>% .$osm_polygons
mtxpk <- st_distance(x=Medellin_D,y=park)
Medellin_D$dist_park <- apply(mtxpk,1,mean)

park <- opq(bbox = getbb("Cali Colombia")) %>%
  add_osm_feature(key = "leisure", value = "park") %>%
  osmdata_sf() %>% .$osm_polygons
mtxpk <- st_distance(x=Cali_D,y=park)
Cali_D$dist_park <- apply(mtxpk,1,mean)

# 3.3.12 Water

water <- opq(bbox = getbb("Bogotá Distrito Capital - Municipio")) %>%
  add_osm_feature(key = "waterway", value=c("river","stream","canal")) %>%
  osmdata_sf() %>% .$osm_lines
mtxwt <- st_distance(x=Bogota_DC,y=water)
Bogota_DC$dist_water <- apply(mtxwt,1,mean)

water <- opq(bbox = getbb("Medellín Colombia")) %>%
  add_osm_feature(key = "waterway", value=c("river","stream","canal")) %>%
  osmdata_sf() %>% .$osm_lines
mtxwt <- st_distance(x=Medellin_D,y=water)
Medellin_D$dist_water <- apply(mtxwt,1,mean)

water <- opq(bbox = getbb("Cali Colombia")) %>%
  add_osm_feature(key = "waterway", value=c("river","stream","canal")) %>%
  osmdata_sf() %>% .$osm_lines
mtxwt <- st_distance(x=Cali_D,y=water)
Cali_D$dist_water <- apply(mtxwt,1,mean)


# 3.3.13 Roads

road1 <- opq(bbox = getbb("Bogotá Distrito Capital - Municipio")) %>%
  add_osm_feature(key = "highway", value=c("trunk")) %>%
  osmdata_sf() %>% .$osm_lines
mtxrd1 <- st_distance(x=Bogota_DC,y=road1)
tdist_rd1 <- apply(mtxrd1,1,mean)

road2 <- opq(bbox = getbb("Bogotá Distrito Capital - Municipio")) %>%
  add_osm_feature(key = "highway", value=c("primary")) %>%
  osmdata_sf() %>% .$osm_lines
mtxrd2 <- st_distance(x=Bogota_DC,y=road2)
tdist_rd2 <- apply(mtxrd2,1,mean)

#road2 <- opq(bbox = getbb("Bogotá Distrito Capital - Municipio")) %>%
#  add_osm_feature(key = "highway", value=c("secondary")) %>%
#  osmdata_sf() %>% .$osm_lines
#mtxrd2 <- st_distance(x=Bogota_DC,y=road2)
#tdist_rd2 <- apply(mtxrd2,1,mean)

tdist_rd <- list()
for (n in 1:37985){
  tdist_rd[n] = 0.3*tdist_rd1[n] + 0.7*tdist_rd2[n]
}
tdist_rd <- as.data.frame(tdist_rd)
tdist_rd <- t(tdist_rd)
Bogota_DC$dist_road <- tdist_rd

road1 <- opq(bbox = getbb("Medellín Colombia")) %>%
  add_osm_feature(key = "highway", value=c("trunk","primary")) %>%
  osmdata_sf() %>% .$osm_lines
mtxrd1 <- st_distance(x=Medellin_D,y=road1)
Medellin_D$dist_road <- apply(mtxrd1,1,mean)

road1 <- opq(bbox = getbb("Cali Colombia")) %>%
  add_osm_feature(key = "highway", value=c("trunk","primary")) %>%
  osmdata_sf() %>% .$osm_lines
mtxrd1 <- st_distance(x=Cali_D,y=road1)
Cali_D$dist_road <- apply(mtxrd1,1,mean)

## 4. Juntar bases de datos

geoprop2 <- rbind(Cali_D,Bogota_DC,Medellin_D)

# 4.1 Distance non-linealities

geoprop2$dist_cent2 <- geoprop2$dist_cent^2
geoprop2$dist_air2 <- geoprop2$dist_air^2
geoprop2$dist_bus2 <- geoprop2$dist_bus^2
geoprop2$dist_hosp2 <- geoprop2$dist_hosp^2
geoprop2$dist_pol2 <- geoprop2$dist_pol^2
geoprop2$dist_shop2 <- geoprop2$dist_shop^2
geoprop2$dist_bar2 <- geoprop2$dist_bar^2
geoprop2$dist_univ2 <- geoprop2$dist_univ^2
geoprop2$dist_rest2 <- geoprop2$dist_rest^2
geoprop2$dist_scho2 <- geoprop2$dist_scho^2
geoprop2$dist_park2 <- geoprop2$dist_park^2
geoprop2$dist_water2 <- geoprop2$dist_water^2
geoprop2$dist_road2 <- geoprop2$dist_road^2

# 4.2 Export

export(geoprop2,"datosgeoesp.rds")

dbge <- readRDS("datosgeoesp.Rds")

## 5. Imputación de missings por manzana mediante KNN

missmnz_bo = sum(is.na(dbge$COD_DANE))/nrow(dbge)

dbge2 <- st_drop_geometry(dbge)

bymnz <- dbge2  %>% group_by(COD_DANE) %>% summarise(count=n())

bymnz <- filter(bymnz,COD_DANE>0)

mean(bymnz$count)

median(bymnz$count) 

# Dado que la manzana mediana posee dos de las propiedades que tenemos como objetivo,
# La imputación por KNN será con un k=3

dbge2$lat = geoprop$lat
dbge2$lon = geoprop$lon

imptdb <- select(dbge2,"property_id","med_H_NRO_CUARTOS","sum_HA_TOT_PER","med_V_TOT_HOG","med_VA1_ESTRATO","lat","lon")

imptdb <- as.matrix.data.frame(imptdb)

write.csv(imptdb,"imptdb.csv",row.names = FALSE)

# EL proceso de imputacion se realizó en el archiv KNNImputer.ipynb

imptdb <- read.csv("imptdb2.csv",header=TRUE)

dbge3 <- left_join(dbge,imptdb,by = c("property_id"))


# Oldcode
#nm = c("Bogotá Distrito Capital - Municipio","Medellín Colombia","Cali Colombia")

#for (vl in 1:3){
#  vps[[vl]] <- opq(bbox = getbb(nm[vl])) %>%
#    add_osm_feature(key = "highway", value=c("trunk","primary","secondary","tertiary")) %>%
#    osmdata_sf() %>% .$osm_lines
#}