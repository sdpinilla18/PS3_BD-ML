#------------------------------------------------------------------------------#
# BD&MLfAE, PS3
# 14 de noviembre de 2022
# R version 4.1.2
# 
# David Santiago Caraballo Candela, 201813007
# Sergio David Pinilla Padilla, 201814755
# Juan Diego Valencia Romero, 201815561
#
# Nota: Codigo complementario de Datos_Geoesp.R, el codigo base para el manejo
# de datos a nivel de manzana fue desarrollado por Eduard Martinez y Lucas Gomez,
# y se encuentra en https://bloqueneon.uniandes.edu.co/content/enforced/138407-UN_202220_ECON_4005/11_vecinos_espaciales.html?ou=138407&d2l_body_type=3#[3]_Vecinos_espaciales
#------------------------------------------------------------------------------#

## load packages
require(pacman) 
p_load(tidyverse,rio)

# Los datos para cada una de las ciudades (Bogotá, Medellín y Cali) se pueden 
# descargar en el siguiente link
browseURL("https://microdatos.dane.gov.co//catalog/643/get_microdata")

##=== variables ===##

## COD_DANE_ANM: Codigo DANE de manzana
## UA_CLASE: ID
## COD_ENCUESTAS: ID de encuesta
## U_VIVIENDA: ID de vivienda
## H_NRO_CUARTOS: Número de cuartos en total
## HA_TOT_PER: Total personas en el hogar
## V_TOT_HOG: Total de hogares en la vivienda
## VA1_ESTRATO: Estrato de la vivienda (según servicio de energía)


##=== Bogota, load data ===##

## unzip file
unzip(zipfile="Censo/11_BOGOTA_CSV.zip" , exdir="Censo/." , overwrite=T) 

## data manzanas
mgn_bog <- import("Censo/CNPV2018_MGN_A2_11.CSV")
colnames(mgn_bog)
mgn_bog <- mgn_bog %>% select(COD_DANE_ANM,UA_CLASE,COD_ENCUESTAS,U_VIVIENDA)

## data hogar
hog_bog <- import("Censo/CNPV2018_2HOG_A2_11.CSV")
colnames(hog_bog)
hog_bog <- hog_bog %>% select(UA_CLASE,COD_ENCUESTAS,U_VIVIENDA,H_NROHOG,H_NRO_CUARTOS,HA_TOT_PER)

## data vivienda
viv_bog <- import("Censo/CNPV2018_1VIV_A2_11.CSV") 
colnames(viv_bog)
viv_bog <- viv_bog %>% select(COD_ENCUESTAS,UA_CLASE,U_VIVIENDA,V_TOT_HOG,VA1_ESTRATO)

## join hogar-vivienda
viv_hog_bog <- left_join(hog_bog,viv_bog,by=c("COD_ENCUESTAS","U_VIVIENDA","UA_CLASE"))

## joing mnz-hogar-vivienda
viv_hog_mgn_bog <- left_join(viv_hog_bog,mgn_bog,by=c("UA_CLASE","COD_ENCUESTAS","U_VIVIENDA"))

##=== collapse data ===##
db_bog <- viv_hog_mgn_bog %>%
      group_by(COD_DANE_ANM) %>% 
      summarise(med_H_NRO_CUARTOS=median(H_NRO_CUARTOS,na.rm=T), 
                sum_HA_TOT_PER=sum(HA_TOT_PER,na.rm=T), 
                med_V_TOT_HOG=median(V_TOT_HOG,na.rm=T),
                med_VA1_ESTRATO=median(VA1_ESTRATO,na.rm=T))

## export data
#export(db_bog,"mnzbog_censo_2018.rds")



##=== Medellin, load data ===##

## unzip file
unzip(zipfile="Censo/05_ANTIOQUIA_CSV.zip" , exdir="Censo/." , overwrite=T) 

## data manzanas
mgn_med <- import("Censo/CNPV2018_MGN_A2_05.CSV")
colnames(mgn_med)
mgn_med <- filter(mgn_med, U_MPIO==1)
mgn_med <- mgn_med %>% select(COD_DANE_ANM,UA_CLASE,COD_ENCUESTAS,U_VIVIENDA)

## data hogar
hog_med <- import("Censo/CNPV2018_2HOG_A2_05.CSV")
colnames(hog_med)
hog_med <- filter(hog_med, U_MPIO==1)
hog_med <- hog_med %>% select(UA_CLASE,COD_ENCUESTAS,U_VIVIENDA,H_NROHOG,H_NRO_CUARTOS,HA_TOT_PER)

## data vivienda
viv_med <- import("Censo/CNPV2018_1VIV_A2_05.CSV") 
colnames(viv_med)
viv_med <- filter(viv_med, U_MPIO==1)
viv_med <- viv_med %>% select(COD_ENCUESTAS,UA_CLASE,U_VIVIENDA,V_TOT_HOG,VA1_ESTRATO)

## join hogar-vivienda
viv_hog_med <- left_join(hog_med,viv_med,by=c("COD_ENCUESTAS","U_VIVIENDA","UA_CLASE"))

## joing mnz-hogar-vivienda
viv_hog_mgn_med <- left_join(viv_hog_med,mgn_med,by=c("UA_CLASE","COD_ENCUESTAS","U_VIVIENDA"))

##=== collapse data ===##
db_med <- viv_hog_mgn_med %>%
  group_by(COD_DANE_ANM) %>% 
  summarise(med_H_NRO_CUARTOS=median(H_NRO_CUARTOS,na.rm=T), 
            sum_HA_TOT_PER=sum(HA_TOT_PER,na.rm=T), 
            med_V_TOT_HOG=median(V_TOT_HOG,na.rm=T),
            med_VA1_ESTRATO=median(VA1_ESTRATO,na.rm=T))

## export data
#export(db_med,"mnzmed_censo_2018.rds")



##=== Cali, load data ===##

## unzip file
unzip(zipfile="Censo/76_VALLEDELCAUCA_CSV.zip" , exdir="Censo/." , overwrite=T) 

## data manzanas
mgn_cal <- import("Censo/CNPV2018_MGN_A2_76.CSV")
colnames(mgn_cal)
mgn_cal <- filter(mgn_cal, U_MPIO==1)
mgn_cal <- mgn_cal %>% select(COD_DANE_ANM,UA_CLASE,COD_ENCUESTAS,U_VIVIENDA)

## data hogar
hog_cal <- import("Censo/CNPV2018_2HOG_A2_76.CSV")
colnames(hog_cal)
hog_cal <- filter(hog_cal, U_MPIO==1)
hog_cal <- hog_cal %>% select(UA_CLASE,COD_ENCUESTAS,U_VIVIENDA,H_NROHOG,H_NRO_CUARTOS,HA_TOT_PER)

## data vivienda
viv_cal <- import("Censo/CNPV2018_1VIV_A2_76.CSV") 
colnames(viv_cal)
viv_cal <- filter(viv_cal, U_MPIO==1)
viv_cal <- viv_cal %>% select(COD_ENCUESTAS,UA_CLASE,U_VIVIENDA,V_TOT_HOG,VA1_ESTRATO)

## join hogar-vivienda
viv_hog_cal <- left_join(hog_cal,viv_cal,by=c("COD_ENCUESTAS","U_VIVIENDA","UA_CLASE"))

## joing mnz-hogar-vivienda
viv_hog_mgn_cal <- left_join(viv_hog_cal,mgn_cal,by=c("UA_CLASE","COD_ENCUESTAS","U_VIVIENDA"))

##=== collapse data ===##
db_cal <- viv_hog_mgn_cal %>%
  group_by(COD_DANE_ANM) %>% 
  summarise(med_H_NRO_CUARTOS=median(H_NRO_CUARTOS,na.rm=T), 
            sum_HA_TOT_PER=sum(HA_TOT_PER,na.rm=T), 
            med_V_TOT_HOG=median(V_TOT_HOG,na.rm=T),
            med_VA1_ESTRATO=median(VA1_ESTRATO,na.rm=T))

## export data
#export(db_cal,"mnzcal_censo_2018.rds")


##=== MNZ Data ===##

mnz_data <-rbind(db_bog,db_med,db_cal)

export(mnz_data,"mnzdata_censo_2018.rds")


