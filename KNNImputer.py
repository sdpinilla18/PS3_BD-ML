#!/usr/bin/env python
# coding: utf-8

# In[1]:


#------------------------------------------------------------------------------#
# BD&MLfAE, PS3
# 14 de noviembre de 2022
# Python 3.9.12
# 
# David Santiago Caraballo Candela, 201813007
# Sergio David Pinilla Padilla, 201814755
# Juan Diego Valencia Romero, 201815561
#
# Nota: Codigo complementario de Datos_Geoesp.R, utilizado para la imputación
# de datos faltantes a nivel de manzana
#------------------------------------------------------------------------------#


# In[ ]:


#Packages:
import pandas as pd
import numpy as np
import pyreadr as pyr
import sklearn as sk
from sklearn.impute import KNNImputer


# In[2]:


imp=pd.read_csv("imptdb.csv")
imp
prop=imp["property_id"]
prop
#imp=pd.DataFrame(imp[1],index=range(0,56436))
#imp


# In[3]:


imp.set_index("property_id",inplace=True)
imp


# In[4]:


imputer=KNNImputer(n_neighbors=3) 
imputer.fit(imp)
dfimp=pd.DataFrame(imputer.transform(imp))


# In[5]:


dfimp
dfimp.set_index(prop,inplace=True)
dfimp


# In[6]:


dict=({0: "med_H_Cuar_KNN", 1: "sum_TOT_Per_KNN", 2: "med_TOT_Hog_KNN", 3: "med_Estrato", 4: "lat", 5: "lon"})
dfimp.rename(columns=dict, inplace=True)


# 

# In[7]:


imputKNN=dfimp.to_csv("C:/Users/hp/OneDrive - Universidad de los Andes/Documentos/Docs/Universidad/2022-2/Big Data/Taller 3/Repo/PS3_BD-ML/imptdb2.csv",index=True)

