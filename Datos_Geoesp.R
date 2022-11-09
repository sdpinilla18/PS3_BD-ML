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

geoprop2 <- st_buffer(x=geoprop1,dist=2000)









