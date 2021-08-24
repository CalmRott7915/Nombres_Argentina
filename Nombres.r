# This script is intended to use corrected data originated in a names dataset from the Argentinian Goverment
# https://datos.gob.ar/dataset/otros-nombres-personas-fisicas
# BSD 3-Clause License
# Copyright (c) 2021, CalmRott7915 (a pseudonym, author can be reached on Reddit under u/CalmRott7915 or on Github)
# Redistributions of source code must retain the above copyright notice and the attached BSD-3 Licence


options(encoding = "UTF-8")
library(data.table)
library(ggplot2)


# Carga los archivos como data.table ####

NC <- fread("Nombres_Completos.csv",
            encoding="UTF-8")

NS <- fread("Nombres_Simples.csv",
            encoding="UTF-8")


# Keys
setkey(NS, Nombre)
setkey(NC,ID)


# Un conjunto de nombres (Cualquiera) ####

ListaNombres=c("Samanta","Samantha")

A <- NS[ListaNombres,.(Total=sum(N)),Yr]

#Plot
G <- ggplot(A)+
  geom_point(aes(x=Yr, y=Total),color="red",size=2)+
  geom_line(aes(x=Yr,y=Total),color="blue",size=1)+
  theme_minimal()+
  scale_x_continuous(breaks=seq(1920,2020,10))+
  labs(x="Año",y="Total",
       title=paste("Evolución de los Nombres: ", paste(ListaNombres,collapse="/"),sep=""))
plot(G)



# Un Conjunto de Nombres Exactos ####
ListaNombres = c("Cristina Elizabeth","Néstor Carlos")
B <- NC[Nombre%in%ListaNombres,.(Total=sum(N)),Yr]

#Plot
G <- ggplot(B)+
  geom_point(aes(x=Yr, y=Total),color="red",size=2)+
  geom_line(aes(x=Yr,y=Total),color="blue",size=1)+
  theme_minimal()+
  scale_x_continuous(breaks=seq(1920,2020,10))+
  labs(x="Año",y="Total",
       title=paste("Evolución de los Nombres: ", paste(ListaNombres,collapse="/"),sep=""))
plot(G)


# Alguno de los nombres de A con Alguno de B ####
A <- c("Raul","Raúl")
B <- c("Ricardo")

AN <- NS[A]
setkey(AN,ID)
BN <- NS[B]
setkey(BN,ID)

#Por defecto es una intersección y se une sobre las claves
C <- merge(AN,BN) 

CN <- NC[J(C$ID),.(N = sum(N)),by=Nombre]
CN <- setorder(CN,-N)

D <- C[,.(Total=sum(N.x)),.(Yr=Yr.x)]


#Plot

Caption <- paste(head(CN,15)[,Nombre], collapse=", ")
Caption <- strwrap(Caption,width=80)
Caption <- paste(Caption, collapse = "\n")
Caption <- paste("Mas Populares:\n", Caption)

Title <- paste("Evolución de los Nombres: ", 
               paste(paste(A,collapse=" o "),
                     paste(B,collapse=" o "),
                     sep=" + "))

G <- ggplot(D)+
  geom_point(aes(x=Yr, y=Total), color="red", size=2)+
  geom_line(aes(x=Yr,y=Total),color="blue",size=1)+
  theme_minimal()+
  scale_x_continuous(breaks=seq(1920,2020,10))+
  theme(plot.caption = element_text(hjust=0)) +
  labs(x="Año",
       y="Total",
       title=Title,
       caption=Caption)
plot(G)


# 20 Nombres más populares de un  año ####
Año = 1970
NCi <- NS[Yr==Año,.(Total=sum(N)),by=Nombre]
NCi <- setorder(NCi,-Total)[1:20,]


#  Total de Inscriptos ####
TI <- NC[,.(Total=sum(N)),keyby=Yr]     
G <- ggplot(TI) + 
    geom_point(aes(x=Yr,y=Total/1e6))+
    geom_line(aes(x=Yr,y=Total/1e6))+
    theme_minimal()+
    labs(title="Número de nombres inscriptos por año",
           x="Año",
           y="Millones") +
    scale_x_continuous(breaks = seq(1920,2020,10))
plot(G)