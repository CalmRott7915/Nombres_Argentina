# This script is intended to correct data originated in a names dataset from the Argentinian Goverment
# https://datos.gob.ar/dataset/otros-nombres-personas-fisicas
# BSD 3-Clause License
# Copyright (c) 2021, CalmRott7915 (a pseudonym, author can be reached on Reddit under u/CalmRott7915 or on Github)
# Redistributions of source code must retain the above copyright notice and the attached BSD-3 Licence

options(encoding = "UTF-8")
library(data.table)
library(stringi)

HN <- fread("historico-nombres.csv",
            encoding="UTF-8",
            sep=NULL,
            col.names="Line")

# Reemplaza los tildes invertidos, algunas mayúsculas extranjeras por minúsculas y otras por caracteres españoles acentuados.
HN[,Line:=stri_trans_char(Line,"àèìòùÀÈÌÒÙÃÕÄËÖÇØêÏÂÊÎÔÛÅ","áéíóúÁÉÍÓÚãõäëöçøéíáéíóúá")]


# Marca como candidatos a correcciones las línea que no responda al formato "Nombre(Alfabético),Cantidad,Año"
HN[,Candidato:=stri_detect_regex(Line,
              "^[a-zA-Z[:space:]áéíóúÁÉÍÓÚñÑüÜçäëïöãõôøâîûý\\-']+,[[:digit:]]+,[[:digit:]]{4}$",
              negate=TRUE)]


# Correcciones sobre las filas que no responden al formato

    # Letra e, está importado de una forma extraña hay veces que el código c282 está sólo y otras precedidas por "e" o "é"
    HN[Candidato==TRUE,Line:=stri_replace_all_regex(Line,"[ée]?\u0082","é")]
    
    # Letra a, es la más compleja, hay veces que está sóla, otras está la "a" o la "á" seguida del código c2a0, y otras hay una letra más en el medio, pero donde el c2a0 (\u00a0) hace las veces de espacio con la palabra siguiente. Así y todo, quedan dos casos especiales que hay que solucionar hardcoded.
    HN[Candidato==TRUE,Line:=stri_replace_all_regex(Line,"[áa](.)?\u00a0","$1á")]
    HN[Candidato==TRUE,Line:=stri_replace_all_fixed(Line,"\u00a0","á")]
    HN[Candidato==TRUE,Line:=stri_replace_all_fixed(Line,"Má x","Máx")]
    HN[Candidato==TRUE,Line:=stri_replace_all_fixed(Line,"Bá rbara","Bárbara")]
    
    # í, ó y ú son más directos.
    HN[Candidato==TRUE,Line:=stri_replace_all_fixed(Line,"\u00a1","í")]
    HN[Candidato==TRUE,Line:=stri_replace_all_fixed(Line,"\u00a2","ó")]
    HN[Candidato==TRUE,Line:=stri_replace_all_fixed(Line,"\u00a3","ú")]
    
    # la ñ está también complicada. El código importado c2a4 a veces reemplaza a una "á" terminada en "an". También en Cármen, Nicolás o Jonás. El resto es ñ o errores de tipeo que no se van a corregir. Los regex de abajo lo hace más o menos bien y dejan un error donde es error.
    HN[Candidato==TRUE,Line:=stri_replace_all_fixed(Line,"\u00a4n","án")]
    HN[Candidato==TRUE,Line:=stri_replace_all_fixed(Line,"C\u00a4rmen","Cármen")]
    HN[Candidato==TRUE,Line:=stri_replace_all_fixed(Line,"\u00a4s","ás")]
    HN[Candidato==TRUE,Line:=stri_replace_all_fixed(Line,"\u00a4","ñ")]
    
    # Elimina las barras verticale, el nombre 2° con ° u º (sí, hay dos)
    HN[Candidato==TRUE,Line:=stri_replace_all_regex(Line,"\\||2?[°º]","")]

        
    
    # Todos los apóstrofes como ' y elimina los repetidos y los que están al comienzo o al final antes de la coma
    HN[Candidato==TRUE,Line:=stri_replace_all_fixed(Line,"`","'")]
    HN[Candidato==TRUE,Line:=stri_replace_all_fixed(Line,"´","'")]
    HN[Candidato==TRUE,Line:=stri_replace_all_regex(Line,"'{2,}","'")]
    HN[Candidato==TRUE,Line:=stri_replace_all_regex(Line,"^'","")]
    HN[Candidato==TRUE,Line:=stri_replace_all_regex(Line,"',",",")]
    
    # Elimina las comillas, y las comas entre las comillas
    HN[Candidato==TRUE,Line:=stri_replace_all_regex(Line,'"([^,]*),([^,]*)"',"$1 $2")]
    HN[Candidato==TRUE,Line:=stri_replace_all_fixed(Line,'"',"")]

    

    # Elimina todo lo que esté entre paréntesis y entre la apertura de un paréntesis y la primera coma.
    HN[Candidato==TRUE,Line:=stri_replace_all_regex(Line,"\\([^,]*\\)","")]
    HN[Candidato==TRUE,Line:=stri_replace_all_regex(Line,"\\([^,]*,",",")]

    
    
    # Guión bajo por espacio 
    HN[Candidato==TRUE,Line:=stri_replace_all_fixed(Line,"_"," ")]

    # Elimina todos los puntos 
    HN[Candidato==TRUE,Line:=stri_replace_all_fixed(Line,".","")]

    
    HN[,Candidato:=NULL]    

# Limpia otros problemas que igual responden al formato general
    
# Reemplaza 2 o más espacios por uno sólo
HN[,Line:=stri_replace_all_regex(Line,"[[:space:]]{2,}"," ")]


# Guiones intermedios sin espacios a los costados 
# (dos replace_all_fixed son más rápidos que un regex con |)
HN[,Line:=stri_replace_all_fixed(Line," - ","-")]
HN[,Line:=stri_replace_all_fixed(Line," -","-")]
HN[,Line:=stri_replace_all_fixed(Line,"- ","-")]


# Elimina espacios antes de las comas
HN[,Line:=stri_replace_all_regex(Line,"[[:space:]]+,",",")]

# Elimina los espacios después de las comas
HN[,Line:=stri_replace_all_regex(Line,",[[:space:]]+",",")]


# Elimina los "Sale Observado" y "Numeracion Pendiente" y otras
HN[,Line:=stri_replace_all_regex(Line,
                                 "[sS]ale Observado[^,]*,|Numeracion Pendiente[^,]*,|[Ff]allecido[^,]*,|[pP]resunto[^,]*,",
                                 ",")]


# Elimina los espacios al comienzo de la línea y al final de una línea
HN[,Line:=stri_replace_all_regex(Line,",^[[:space:]]+","")]
HN[,Line:=stri_replace_all_regex(Line,",[[:space:]]+$","")]

#Elimina Todos los nómbres de una sóla letra que no vay al al comienzo ni al final
HN[,Line:=stri_replace_all_regex(Line,"[[:space:]][[:alpha:]][[:space:]]"," ")]

#Elimina Todos los nómbres de una sóla letra que están al final de una línea
HN[,Line:=stri_replace_all_regex(Line,"[[:space:]][[:alpha:]],",",")]

#Cambia una letra y espacio al comienzo por Letra y guión (por ejemplo A Chang --> A-Chang)
HN[,Line:=stri_replace_all_regex(Line,"^([[:alpha:]])[[:space:]]","$1-")]


# Elimina cualquier símbolo que no sea una letra al comienzo
HN[,Line:=stri_replace_all_regex(Line,
           "^[^a-zA-ZáéíóúÁÉÍÓÚñÑüÜçäëïöãõôâîûý]+(.*)",
           "$1")]

# Marca para borrar las líneas dond se eliminó tódo
HN[,keep:=(stri_length(Line)>=2)]


# Marca para corregir las línea que no responda al formato "Nombre(Alfabético),Cantidad,Año"
HN[,Corr:=stri_detect_regex(Line,
          "^[a-zA-Z[:space:]áéíóúÁÉÍÓÚñÑüÜçäëïöãõôøâîûý\\-']+,[[:digit:]]+,[[:digit:]]{4}$",
          negate=TRUE)]


# Escribe lo que hay para corregir
write.table (x = HN[Corr==TRUE&keep==TRUE,Line],
             file="Nombres-Problema-R.csv",
             row.names=FALSE,
             col.names=FALSE,
             quote=FALSE,
             fileEncoding = "UTF-8")


# Escribe lo que está bien, primero la fila de nombres y después el resto
write.table(x = "Nombre,N,Yr",
            file= "Nombres-Limpio-R.csv",
            row.names=FALSE,
            col.names=FALSE,
            quote=FALSE)

write.table(x=HN[Corr==FALSE&keep==TRUE,Line],
            file = "Nombres-Limpio-R.csv",
            row.names=FALSE,
            col.names=FALSE,
            quote=FALSE,
            append=TRUE)


