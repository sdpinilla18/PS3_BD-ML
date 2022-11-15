## Repositorio Taller 3

**Facultad de Economía**

**Universidad de los Andes**

Integrantes: [David Santiago Caraballo Candela](https://github.com/scaraballoc), [Sergio David Pinilla Padilla](https://github.com/sdpinilla18) y [Juan Diego Valencia Romero](https://github.com/judval).

En el presente repositorio se encuentran todos los documentos, bases de datos y códigos utilizados durante el desarrollo del Taller 3 de la clase *Big Data & Machine Learning for Applied Economics*, del profesor [Ignacio Sarmiento-Barbieri](https://ignaciomsarmiento.github.io/igaciomsarmiento) durante el segundo semestre del año 2022.

Este trabajo tenía como objetivo el desarrollo de un modelo de predicción de precios de vivienda para determinar la factibilidad de adquirirla y monetizar a través de su remodelación y reventa, a partir del uso de una base de datos del 2021 para la ciudad de Cali del sitio web PROPERATI. Tal insumo, con la intención de mejorar el proceso de identificación de precios por debajo del umbral de compra (<COP $40.000.000). Se importa toda la *raw-database* de PROPERATI 2021 que contiene un total de 51.437 observaciones y 14 variables que resulta de compilar las viviendas de Bogotá D.C. y Medellín. 
 
**1. *Data cleaning & Modelling***

La estrategia empírica del trabajo sigue el orden del objetivo. Se inició limpiando el texto de las descripciones y título de los anuncios en la base de datos de entrenamiento. Posteriormente, a partir de expresiones regulares, se hallaron nuevos predictores relacionados con amenidades, servivcios o bienes privados/públicos propios de la vivienda o aledaños. En esta misma línea, se buscaron datos geo-espaciales para construir los mapas de cercanía toda vez que aportaba robustez a la base. El modelo de predicción correspondió a un SuperLearner con tres sub-modelos; i) XGBoost (9 especificaciones); ii) Redes Neuronales (6 especificaciones), y; iii) Lasso (8 especificaciones) con una funcion de pérdida personalizada ABS-EXP que pondera en valor absoluto a las predicciones por debajo del precio de lista hasta COP $40 millones y exponencialmente aquellos por encima o debajo de este umbral.  

Para poder utilizar nuestro código de **Python**, es necesario tener instalados los paquetes de `numpy`, `pyread`, `sklearn`, `pandas`, `scipy`, `contexto`, `nltk`, `spacy`, `xgboost` y `matplotlib`; de los cuales se importan diversas librerías. El código completo, que incluye todo el proceso de limpieza de datos, extracción de estadísticas descriptivas y el análisis empírico para responder a las preguntas del *problem set* se encuentran en orden dentro del notebook de Jupyter titulado "PS3_BD.ipynb". El *Python script* asociado al notebook esta titulado como "T3Script.py" y el archivo final que determina las predicciones se nombra "predictions_caraballo_pinilla_valencia.csv".

***Nota:*** *Este archivo debería correr a la perfección siempre y cuando se sigan las instrucciones y comentarios del código (en orden y forma). Es altamente recomendable que antes de verificar la replicabilidad del código, se asegure de tener **todos** los requerimientos informáticos previamente mencionados (i.e. se prefieren versiones de **Python** menores a la 3.10.9 para evitar que paquetes, funciones y métodos que han sido actualizados no funcionen). Además, la velocidad de ejecución dependerá de las características propias de su máquina, por lo que deberá (o no) tener paciencia mientras se procesa.*
