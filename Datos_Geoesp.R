#------------------------------------------------------------------------------#
# BD&MLfAE, PS3
# 14 de noviembre de 2022
# R version 4.1.2
# 
# David Santiago Caraballo Candela, 201813007
# Sergio David Pinilla Padilla, 201814755
# Juan Diego Valencia Romero, 201815561
#
# Nota: Principal codigo utilizado durante el PS3 para extracción y analisis
# de datos geoespaciales. Esta complementado por Prepare_Censo.R para la 
# extracción de datos a nivel de manzanas, y por KNNImputer.ipynb o por 
# KNNImputer.py para la imputación de missings en los datos a nivel de manzana.
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

# Los datos a nivel de manzanas se pueden encontrar en 
# https://geoportal.dane.gov.co/servicios/descarga-y-metadatos/descarga-mgn-marco-geoestadistico-nacional/

mnz <- st_read("MNZ/MGN_URB_MANZANA.shp")

mnz <- st_transform(mnz,crs=4326)

mnz <- filter(mnz, COD_MPIO %in% c("05001","11001","76001") )

geoprop1 <- st_join(geoprop1,mnz)

# Los datos de mnzdata_censo_2018.Rds fueron preparados utilizando el codigo 
# Prepare_Censo.R

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
# la imputación por KNN será con un k=3.

dbge2$lat = geoprop$lat
dbge2$lon = geoprop$lon

imptdb <- select(dbge2,"property_id","med_H_NRO_CUARTOS","sum_HA_TOT_PER","med_V_TOT_HOG","med_VA1_ESTRATO","lat","lon")

imptdb <- as.matrix.data.frame(imptdb)

write.csv(imptdb,"imptdb.csv",row.names = FALSE)

# EL proceso de imputacion se realizó en el archivo KNNImputer.ipynb o
# se puede revisar su analogo KNNImputer.py

imptdb <- read.csv("imptdb2.csv",header=TRUE)

dbge3 <- left_join(dbge,imptdb,by = c("property_id"))

dbge3$med_H_Cuar_KNN <- round(dbge3$med_H_Cuar_KNN, digits = 0)
dbge3$sum_TOT_Per_KNN <- round(dbge3$sum_TOT_Per_KNN, digits = 0)
dbge3$med_TOT_Hog_KNN <- round(dbge3$med_TOT_Hog_KNN, digits = 0)
dbge3$med_Estrato <- round(dbge3$med_Estrato, digits = 0)

export(dbge3,"datosgeoesp.rds")

write.csv(dbge3,"datosgeoesp.csv",row.names = FALSE)

# 5.2 Export, try again

dbge_clean <- dbge3 %>% select('property_id', 'city',  'med_H_NRO_CUARTOS', 'sum_HA_TOT_PER', 'med_V_TOT_HOG',
                         'med_VA1_ESTRATO', 'dist_cent', 'dist_air', 'dist_bus', 'dist_hosp',
                         'dist_pol', 'dist_shop', 'dist_bar', 'dist_univ', 'dist_rest',
                         'dist_scho', 'dist_park', 'dist_water', 'dist_road', 'dist_cent2',
                         'dist_air2', 'dist_bus2', 'dist_hosp2', 'dist_pol2', 'dist_shop2',
                         'dist_bar2', 'dist_univ2', 'dist_rest2', 'dist_scho2', 'dist_park2',
                         'dist_water2', 'dist_road2', 'med_H_Cuar_KNN', 'sum_TOT_Per_KNN',
                         'med_TOT_Hog_KNN', 'med_Estrato')

write.csv(dbge_clean,"datosgeoesp2.csv",row.names = FALSE)

dbge_clean <- read.csv("datosgeoesp2.csv")


## 6. Estadisticas descriptivas

amenities_sum <- dbge3 %>% group_by(city) %>% summarise(dcent=mean(dist_cent),dair=mean(dist_air),dbus=mean(dist_bus),dhosp=mean(dist_hosp),dpol=mean(dist_pol),dshop=mean(dist_shop),dbar=mean(dist_bar),duniv=mean(dist_univ),drest=mean(dist_rest),dschool=mean(dist_scho),dpark=mean(dist_park),dwater=mean(dist_water),droad=mean(dist_road))

amenities_sum = t(amenities_sum)

amenities_summd <- dbge3 %>% group_by(city) %>% summarise(dcent=median(dist_cent),dair=median(dist_air),dbus=median(dist_bus),dhosp=median(dist_hosp),dpol=median(dist_pol),dshop=median(dist_shop),dbar=median(dist_bar),duniv=median(dist_univ),drest=median(dist_rest),dschool=median(dist_scho),dpark=median(dist_park),dwater=median(dist_water),droad=median(dist_road))

amenities_summd = t(amenities_summd)


demeco_sum <- dbge3 %>% group_by(city) %>% summarise(mdCuar=median(med_H_Cuar_KNN),mdPer=median(sum_TOT_Per_KNN),mdHog=median(med_TOT_Hog_KNN),mdEst=median(med_Estrato))

demeco_sum = t(demeco_sum)


## 7. Mapas

# 7.1 Distancia al transporte publico

fin_bog <- filter(dbge3,city=="Bogotá D.C")

UPZ = opq(bbox = getbb(place_name = "Bogotá Colombia",
                           featuretype = "boundary:administrative",
                           format_out = "sf_polygon")) %>%
  add_osm_feature(key = "admin_level", value = "9") %>%
  osmdata_sf()  %>% .$osm_multipolygons

UPZ = UPZ %>% subset(str_detect(ref,"")) 
UPZ = st_cast(UPZ,"POLYGON") 


bs_bog <- ggplot(data=fin_bog) + geom_sf(data=UPZ,fill=NA,color = "black") +
                       geom_sf(data=fin_bog,aes(color=dist_bus),size=0.5,shape=0) +
                       scale_color_gradient(low="darkred",high="brown1",name="Minima distancia a estación de Bus (mt)") +
                       #scale_alpha()
                       geom_sf(data=cent_bog,fill=NA,color="black",size=3) +
                       theme(legend.position="bottom",legend.text = element_text(size = 6),panel.background = element_rect(fill = "white"),panel.grid.major = element_line(color = "lightgray", size = 0.2),panel.border = element_rect(fill=NA,colour = "black")) +
                       #theme_bw() +
                       north(data=UPZ , location="topleft") + 
                       scalebar(data=UPZ , location="bottomleft" , dist=2 , dist_unit="km" , transform=T, model="WGS84", st.size = 2.5) + 
                       labs(x = NULL, y = NULL)

bs_bog

ggsave("BS_Distance_Bog.jpeg", plot=last_plot(), device = "jpeg", 
       scale = 1, dpi = "print", limitsize = T, bg = NULL)


fin_med <- filter(dbge3,city=="Medellín")

ComMed = opq(bbox = getbb(place_name = "Medellín Colombia",
                       featuretype = "boundary:administrative",
                       format_out = "sf_polygon")) %>%
  add_osm_feature(key = "admin_level", value = "8") %>%
  osmdata_sf()  %>% .$osm_multipolygons

#ComMed = ComMed %>% subset(str_detect(ref,"")) 
ComMed = st_cast(ComMed,"POLYGON")

bs_med <- ggplot(data=fin_med) + geom_sf(data=ComMed,fill=NA,color = "black") +
                       geom_sf(data=fin_med,aes(color=dist_bus),size=0.5,shape=0) +
                       scale_color_gradient(low="darkred",high="brown1",name="Minima distancia a estación de Bus (mt)") +
                       #scale_alpha()
                       geom_sf(data=cent_med,fill=NA,color="black",size=3) +
                       theme(legend.position="bottom",legend.text = element_text(size = 6),panel.background = element_rect(fill = "white"),panel.grid.major = element_line(color = "lightgray", size = 0.2),panel.border = element_rect(fill=NA,colour = "black")) +
                       #theme_bw() +
                       north(data=ComMed , location="topleft") + 
                       scalebar(data=ComMed , location="bottomleft" , dist=2 , dist_unit="km" , transform=T, model="WGS84", st.size = 2.5) +
                       labs(x = NULL, y = NULL)

bs_med

ggsave("BS_Distance_Med.jpeg", plot=last_plot(), device = "jpeg", 
       scale = 1, dpi = "print", limitsize = T, bg = NULL)


fin_Cali <- filter(dbge3,city=="Cali")

ComCal = opq(bbox = getbb(place_name = "Cali Colombia",
                          featuretype = "boundary:administrative",
                          format_out = "sf_polygon")) %>%
  add_osm_feature(key = "admin_level", value = "8") %>%
  osmdata_sf()  %>% .$osm_multipolygons

#ComMed = ComMed %>% subset(str_detect(ref,"")) 
ComCal = st_cast(ComCal,"POLYGON")

bs_cal <- ggplot(data=fin_Cali) + geom_sf(data=ComCal,fill=NA,color = "black") +
  geom_sf(data=fin_Cali,aes(color=dist_bus),size=0.5,shape=0) +
  scale_color_gradient(low="darkred",high="brown1",name="Minima distancia a estación de Bus (mt)") +
  #scale_alpha()
  geom_sf(data=cent_cal,fill=NA,color="black",size=3) +
  theme(legend.position="bottom",legend.text = element_text(size = 6),panel.background = element_rect(fill = "white"),panel.grid.major = element_line(color = "lightgray", size = 0.2),panel.border = element_rect(fill=NA,colour = "black")) +
  #theme_bw() +
  north(data=ComCal , location="topleft") + 
  scalebar(data=ComCal , location="bottomleft" , dist=2 , dist_unit="km" , transform=T, model="WGS84", st.size = 2.5) +
  labs(x = NULL, y = NULL)

bs_cal

ggsave("BS_Distance_Cal.jpeg", plot=last_plot(), device = "jpeg", 
       scale = 1, dpi = "print", limitsize = T, bg = NULL)

library(ggplot2)
library(ggpubr)

dist_bs <- ggarrange(bs_bog, bs_med, bs_cal,
                    labels = c("Bogotá D.C", "Medellín", "Cali"),
                    ncol = 3, nrow = 1)
dist_bs

ggsave("BS_Distance.jpeg", plot=last_plot(), device = "jpeg", 
       scale = 1, dpi = "print", limitsize = T, bg = NULL)

# 7.2 Distancia a tiendas y centros comerciales

sh_bog <- ggplot(data=fin_bog) + geom_sf(data=UPZ,fill=NA,color = "black") +
  geom_sf(data=fin_bog,aes(color=dist_shop),size=0.5,shape=0) +
  scale_color_gradient(low="darkgoldenrod4",high="bisque1",name="Minima distancia a Tiendas o C.C. (mt)") +
  #scale_alpha()
  geom_sf(data=cent_bog,fill=NA,color="black",size=3) +
  theme(legend.position="bottom",legend.text = element_text(size = 6),panel.background = element_rect(fill = "white"),panel.grid.major = element_line(color = "lightgray", size = 0.2),panel.border = element_rect(fill=NA,colour = "black")) +
  #theme_bw() +
  north(data=UPZ , location="topleft") + 
  scalebar(data=UPZ , location="bottomleft" , dist=2 , dist_unit="km" , transform=T, model="WGS84", st.size = 2.5) + 
  labs(x = NULL, y = NULL)

sh_bog

ggsave("SH_Distance_Bog.jpeg", plot=last_plot(), device = "jpeg", 
       scale = 1, dpi = "print", limitsize = T, bg = NULL)


sh_med <- ggplot(data=fin_med) + geom_sf(data=ComMed,fill=NA,color = "black") +
  geom_sf(data=fin_med,aes(color=dist_shop),size=0.5,shape=0) +
  scale_color_gradient(low="darkgoldenrod4",high="bisque1",name="Minima distancia a Tiendas o C.C. (mt)") +
  #scale_alpha()
  geom_sf(data=cent_med,fill=NA,color="black",size=3) +
  theme(legend.position="bottom",legend.text = element_text(size = 6),panel.background = element_rect(fill = "white"),panel.grid.major = element_line(color = "lightgray", size = 0.2),panel.border = element_rect(fill=NA,colour = "black")) +
  #theme_bw() +
  north(data=ComMed , location="topleft") + 
  scalebar(data=ComMed , location="bottomleft" , dist=2 , dist_unit="km" , transform=T, model="WGS84", st.size = 2.5) + 
  labs(x = NULL, y = NULL)

sh_med

ggsave("SH_Distance_Med.jpeg", plot=last_plot(), device = "jpeg", 
       scale = 1, dpi = "print", limitsize = T, bg = NULL)


sh_cal <- ggplot(data=fin_Cali) + geom_sf(data=ComCal,fill=NA,color = "black") +
  geom_sf(data=fin_Cali,aes(color=dist_shop),size=0.5,shape=0) +
  scale_color_gradient(low="darkgoldenrod4",high="bisque1",name="Minima distancia a Tiendas o C.C. (mt)") +
  #scale_alpha()
  geom_sf(data=cent_cal,fill=NA,color="black",size=3) +
  theme(legend.position="bottom",legend.text = element_text(size = 6),panel.background = element_rect(fill = "white"),panel.grid.major = element_line(color = "lightgray", size = 0.2),panel.border = element_rect(fill=NA,colour = "black")) +
  #theme_bw() +
  north(data=ComCal , location="topleft") + 
  scalebar(data=ComCal , location="bottomleft" , dist=2 , dist_unit="km" , transform=T, model="WGS84", st.size = 2.5) + 
  labs(x = NULL, y = NULL)

sh_cal

ggsave("SH_Distance_Cal.jpeg", plot=last_plot(), device = "jpeg", 
       scale = 1, dpi = "print", limitsize = T, bg = NULL)


dist_sh <- ggarrange(sh_bog, sh_med, sh_cal,
                     labels = c("Bogotá D.C", "Medellín", "Cali"),
                     ncol = 3, nrow = 1)
dist_sh

ggsave("SH_Distance.jpeg", plot=last_plot(), device = "jpeg", 
       scale = 1, dpi = "print", limitsize = T, bg = NULL)

# 7.3 Distancia a parques

park_bog <- opq(bbox = getbb("Bogotá Colombia")) %>%
  add_osm_feature(key = "leisure", value = "park") %>%
  osmdata_sf() %>% .$osm_polygons

pk_bog <- ggplot(data=fin_bog) + geom_sf(data=UPZ,fill=NA,color = "black") +
  #geom_sf(data=fin_bog,aes(color=dist_park),size=0.5,shape=0) +
  #scale_color_gradient(low="darkgreen",high="chartreuse",name="Distancia promedio a parques (mt)") +
  geom_sf(data=park_bog,fill="chartreuse3",color="chartreuse3") +
  #scale_alpha()
  geom_sf(data=cent_bog,color="darkblue",size=3) +
  theme(panel.background = element_rect(fill = "white"),panel.grid.major = element_line(color = "lightgray", size = 0.2),panel.border = element_rect(fill=NA,colour = "black")) +
  #theme_bw() +
  north(data=UPZ , location="topleft") + 
  scalebar(data=UPZ , location="bottomleft" , dist=2 , dist_unit="km" , transform=T, model="WGS84", st.size = 2.5) + 
  labs(x = NULL, y = NULL) +
  ggtitle("Parques en Bogotá")

pk_bog

ggsave("PK_Bog.jpeg", plot=last_plot(), device = "jpeg", 
       scale = 1, dpi = "print", limitsize = T, bg = NULL)


park_med <- opq(bbox = getbb("Perímetro Urbano Medellín")) %>%
  add_osm_feature(key = "leisure", value = "park") %>%
  osmdata_sf() %>% .$osm_polygons

pk_med <- ggplot(data=fin_med) + geom_sf(data=ComMed,fill=NA,color = "black") +
  #geom_sf(data=fin_med,aes(color=dist_park),size=0.5,shape=0) +
  #scale_color_gradient(low="darkgreen",high="chartreuse",name="Distancia promedio a parques (mt)") +
  geom_sf(data=park_med,fill="chartreuse3",color="chartreuse3") +
  #scale_alpha()
  geom_sf(data=cent_med,fill=NA,color="darkblue",size=3) +
  theme(legend.position="bottom",legend.text = element_text(size = 6),panel.background = element_rect(fill = "white"),panel.grid.major = element_line(color = "lightgray", size = 0.2),panel.border = element_rect(fill=NA,colour = "black")) +
  #theme_bw() +
  north(data=ComMed , location="topleft") + 
  scalebar(data=ComMed , location="bottomleft" , dist=2 , dist_unit="km" , transform=T, model="WGS84", st.size = 2.5) + 
  labs(x = NULL, y = NULL) +
  ggtitle("Parques en Medellín")

pk_med

ggsave("PK_Med.jpeg", plot=last_plot(), device = "jpeg", 
       scale = 1, dpi = "print", limitsize = T, bg = NULL)



park_cal <- opq(bbox = getbb("Perímetro Urbano Santiago de Cali")) %>%
  add_osm_feature(key = "leisure", value = "park") %>%
  osmdata_sf() %>% .$osm_polygons

pk_cal <- ggplot(data=fin_Cali) + geom_sf(data=ComCal,fill=NA,color = "black") +
  #geom_sf(data=fin_med,aes(color=dist_park),size=0.5,shape=0) +
  #scale_color_gradient(low="darkgreen",high="chartreuse",name="Distancia promedio a parques (mt)") +
  geom_sf(data=park_cal,fill="chartreuse3",color="chartreuse3") +
  #scale_alpha()
  geom_sf(data=cent_cal,fill=NA,color="darkblue",size=3) +
  theme(legend.position="bottom",legend.text = element_text(size = 6),panel.background = element_rect(fill = "white"),panel.grid.major = element_line(color = "lightgray", size = 0.2),panel.border = element_rect(fill=NA,colour = "black")) +
  #theme_bw() +
  north(data=ComCal , location="topleft") + 
  scalebar(data=ComCal , location="bottomleft" , dist=2 , dist_unit="km" , transform=T, model="WGS84", st.size = 2.5) + 
  labs(x = NULL, y = NULL) +
  ggtitle("Parques en Cali")

pk_cal

ggsave("PK_Cal.jpeg", plot=last_plot(), device = "jpeg", 
       scale = 1, dpi = "print", limitsize = T, bg = NULL)



parks <- ggarrange(pk_bog, pk_med, pk_cal,
                     labels = c("Bogotá D.C", "Medellín", "Cali"),
                     ncol = 3, nrow = 1)
parks

ggsave("PK.jpeg", plot=last_plot(), device = "jpeg", 
       scale = 1, dpi = "print", limitsize = T, bg = NULL)


