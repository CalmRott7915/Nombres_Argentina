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

# Incompleto
# Todas los Nombresa Mayusculas la primera letra
HNL[,Nombre:=stri_trans_totitle(Nombre)]





fwrite(x=HNL,
       file="Nombres_Completos.csv",
       eol="\n",
       row.names=FALSE)


# Genera el listado de nombres individuales

# Dividir en los espacios
NamesSplit <- data.table(stri_split_fixed(HNL[,Nombre],pattern=" ",simplify = TRUE))

# Agrega el ID, Número y Año
NamesSplit[,`:=`(ID=1:.N,N=HNL[,N],Yr=HNL[,Yr])]

#Lo pasa el formato largo
NamesSplit <- melt(NamesSplit,
                   id.vars=c("ID","N","Yr"),
                   variable.name="P",
                   value.name="Nombre")[,P:=NULL]
NamesSplit <- NamesSplit[Nombre!=""]

setcolorder(NamesSplit,c("ID","Nombre","N","Yr"))

# Graba                                        
fwrite(x=NamesSplit,
       file="Nombres_Simples.csv",
       eol="\n",
       row.names=FALSE)


# Limpia los archivos intermedios
 if (file.exists("Nombres-Limpio-R.csv")){
   file.remove("Nombres-Limpio-R.csv")
 }
     
 if (file.exists("Nombres-Problema-R.csv")){
   file.remove("Nombres-Problema-R.csv")
 }
 