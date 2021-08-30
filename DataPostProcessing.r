# This script is intended to correct data originated in a names dataset from the Argentinian Goverment
# https://datos.gob.ar/dataset/otros-nombres-personas-fisicas
# BSD 3-Clause License
# Copyright (c) 2021, CalmRott7915 (a pseudonym, author can be reached on Reddit under u/CalmRott7915 or on Github)
# Redistributions of source code must retain the above copyright notice and the attached BSD-3 Licence

options(encoding = "UTF-8")
library(data.table)
library(stringi)

HNL <- fread("Nombres-Limpio-R.csv",
            encoding="UTF-8")


HNP <- fread("Nombres-Problema-Corregido-R.csv",
             header=FALSE,
             encoding="UTF-8",
             col.names=colnames(HNL))

HNL <- rbindlist(list(HNL,HNP))


# Agrega un ID a cada fila de nombre
HNL[,ID:=1:.N]
setcolorder(HNL,c("ID","Nombre","N","Yr"))


# Todos los Nombresa Mayusculas la primera letra
HNL[,Nombre:=stri_trans_totitle(Nombre)]


fwrite(x=HNL,
       file="Nombres_Completos.csv",
       eol="\n",
       row.names=FALSE)


# Genera el listado de nombres individuales

## Nota. Código original donde la operación de melt se hace en un sólo paso
## Funciona bien pero requiere mucha memoria, sobre todo porque genera tantas
## Columnas como la cantidad de nombres simples en el nombre más largo (11),
## Con lo cual se generan más de 100 millones de entradas
   # 
   # # Dividir en los espacios
   # NamesSplit <- data.table(stri_split_fixed(HNL[,Nombre],pattern=" ",simplify = TRUE))
   # 
   # # Agrega el ID, Número y Año
   # NamesSplit[,`:=`(ID=1:.N,N=HNL[,N],Yr=HNL[,Yr])]
   # 
   # 
   # #Lo pasa al formato largo
   # NamesSplit <- melt(NamesSplit,
   #                    id.vars=c("ID","N","Yr"),
   #                    variable.name="P",
   #                    value.name="Nombre")[,P:=NULL]
   # NamesSplit <- NamesSplit[Nombre!=""]
   # 
   # setcolorder(NamesSplit,c("ID","Nombre","N","Yr"))
   # 
   # # Graba
   # fwrite(x=NamesSplit,
   #        file="Nombres_Simples.csv",
   #        eol="\n",
   #        row.names=FALSE)


# El código de abajo es lo mismo, pero leyendo un grupo de entradas por vez


# Inicializa las columnas
fwrite(x=list("ID","Nombre","N","Yr"),
       file="Nombres_Simples.csv",
       eol="\n",
       row.names=FALSE,
       col.names=FALSE,
       append=FALSE
       )

NRows <- nrow(HNL)
ChunkSize <- 100000L
NChunks <- NRows%/%ChunkSize + sign(NRows%%ChunkSize)

for (i in 0:(NChunks-1)){
   
   # Hace la division de nombres para el chunk actual (iRange)
   iRange <- (i*ChunkSize+1):min(NRows,(i+1)*ChunkSize)
   NamesSplit <- data.table(stri_split_fixed(HNL[iRange,Nombre],pattern=" ",simplify = TRUE))
   NamesSplit[,`:=`(ID=iRange,N=HNL[iRange,N],Yr=HNL[iRange,Yr])]


   #Lo pasa al formato largo
   NamesSplit <- melt(NamesSplit,
                      id.vars=c("ID","N","Yr"),
                      variable.name="P",
                      value.name="Nombre")[,P:=NULL]
   NamesSplit <- NamesSplit[Nombre!=""]
   setcolorder(NamesSplit,c("ID","Nombre","N","Yr"))

   # Agrega al Archivo
   fwrite(NamesSplit,
          file="Nombres_Simples.csv",
          eol="\n",
          row.names=FALSE,
          col.names=FALSE,
          append=TRUE
   )
   
} # Fin lazo de Chunks



# Limpia los archivos intermedios
 if (file.exists("Nombres-Limpio-R.csv")){
   file.remove("Nombres-Limpio-R.csv")
 }

 if (file.exists("Nombres-Problema-R.csv")){
   file.remove("Nombres-Problema-R.csv")
 }
