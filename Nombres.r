# This script is intended to use corrected data originated in a names dataset from the Argentinian Goverment
# https://datos.gob.ar/dataset/otros-nombres-personas-fisicas
# BSD 3-Clause License
# Copyright (c) 2021, CalmRott7915 (a pseudonym, author can be reached on Reddit under u/CalmRott7915 or on Github)
# Redistributions of source code must retain the above copyright notice and the attached BSD-3 Licence


options(encoding = "UTF-8")
library(data.table)
library(ggplot2)
library(plotly)
library(cluster)


# Carga los archivos como data.table ####

NC <- fread("Nombres_Completos.csv",
            encoding="UTF-8")

NS <- fread("Nombres_Simples.csv",
            encoding="UTF-8")

setkey(NS, Nombre)
setkey(NC,ID)

# Agregado de nombres aimples año a año y luego ordenados por frecuencia descendente
NSy <- NS[,.(Total=sum(N)),by="Nombre,Yr"]
setorder(NSy,Yr,-Total)

#####################################################
# Un Conjunto de Nombres Simples (Suma de Todos) ####
#####################################################

ListaNombres=c("Samanta","Samantha")

AN <- NS[ListaNombres]

A <- AN[,.(Total=sum(N)),Yr]
CN <- NC[J(AN$ID),.(N = sum(N)),by=Nombre]

CN <- setorder(CN,-N)

#Plot
Caption <- paste(head(CN,15)[,Nombre], collapse=", ")
Caption <- strwrap(Caption,width=80)
Caption <- paste(Caption, collapse = "\n")
Caption <- paste("Mas Populares:\n", Caption,sep="")

Title <- paste("Evolución de los Nombres: ", paste(ListaNombres,collapse=" o "),sep="")

G <- ggplot(A)+
  geom_point(aes(x=Yr, y=Total),color="red",size=2)+
  geom_line(aes(x=Yr,y=Total),color="blue",size=1)+
  theme_minimal()+
  scale_x_continuous(breaks=seq(1920,2020,10))+
  theme(plot.caption = element_text(hjust=0)) +
  labs(x="Año",
       y="Total",
       title=Title,
       caption=Caption)
plot(G)


#####################################################
# Un Conjunto de Nombres Exactos (Suma de Todos) ####
#####################################################

ListaNombres = c("Cristina Elizabeth","Néstor Carlos")
B <- NC[Nombre%in%ListaNombres,.(Total=sum(N)),Yr]

#Plot
G <- ggplot(B)+
  geom_point(aes(x=Yr, y=Total),color="red",size=2)+
  geom_line(aes(x=Yr,y=Total),color="blue",size=1)+
  theme_minimal()+
  scale_x_continuous(breaks=seq(1920,2020,10))+
  labs(x="Año",y="Total",
       title=paste("Evolución de los Nombres: ", 
                   paste(ListaNombres,collapse="/"),sep=""))
plot(G)

#############################################################################
# Nombres completos que contengan uno o más nombres de A y uno o más de B####
#############################################################################
A <- c("Raul","Raúl")
B <- c("Ricardo")

AN <- NS[A]
setkey(AN,ID)
BN <- NS[B]
setkey(BN,ID)

#Por defecto es una intersección y se une sobre las claves y con solo C <- merge(AN,BN) funciona bien.
C <- merge(AN,BN, by="ID",all=FALSE)

CN <- NC[J(C$ID),.(N = sum(N)),by=Nombre]
CN <- setorder(CN,-N)

D <- C[,.(Total=sum(N.x)),.(Yr=Yr.x)]


#Plot

Caption <- paste(head(CN,15)[,Nombre], collapse=", ")
Caption <- strwrap(Caption,width=80)
Caption <- paste(Caption, collapse = "\n")
Caption <- paste("Mas Populares:\n", Caption,sep="")

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

##########################################
# 20 Nombres más populares de un  año ####
##########################################

Año = 1997
NCi <- NS[Yr==Año,.(Total=sum(N)),by=Nombre]
NCi <- setorder(NCi,-Total)[1:20,]
# Exportar sacando comentario de abajo
# write.csv(NCi, file = Popular20Yr.csv, row.names=FALSE,fileEncoding = "UTF-8")



###########################
#  Total de Inscriptos ####
###########################

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


##################################################
# X Nombres simples más populares de cada año ####
##################################################

PopularX <- function(N_Popular, exclude=c("Del","Los","De")){
  
    NSp <- NSy[,first(.SD,N_Popular),by=Yr]

    # Se recalculan todos los que algunas vez fueron top de un año para todos los años
    
    #La siguiente línea estás convolucionada pero es sólo tener la lista ordenada de nombres que
    #no incluya "Del, "Los" y "De"
    Populares <-NSp[!Nombre%in%exclude,Nombre,keyby=Nombre][,1][,Nombre] 
      
    # Y poner dos  columnas con el total un nombre y el total de inscriptos en cada año
    NSp <- NSy[Nombre%in%Populares]
    Years <- NSp[,Yr]
    NSp[,`:=`(YrTotal=TI[.(Years),Total])]

    # Luego a ppm para hacerlos comparables a traves del tiempo  
    NSp[,ppm:=Total/YrTotal*1e6]
}
    
    
    
############################################################    
# Tabla de 20 Nombres Más Populares por año para exportar  #
############################################################
NCtw <- dcast(PopularX(20),Yr~Nombre,value.var="Total", fill=0)
# write.csv(NCtw,file="Popular20History.csv",row.names = FALSE,fileEncoding = "UTF-8")


###################################################################
# Gráfico de evolución de los nómbres más populares               #
# Hecho en Plotly para poder hacer zoom y mirar con detalle       #
###################################################################

NCht <- PopularX(5)

# Para suavizar el gráfico
NCht[,ppms:=frollmean(ppm,c(1,2,rep(3,.N-2)), adaptive=TRUE), by=Nombre]


# En plotly
plot_ly(NCht,
        x=~Yr,
        y=~ppms,
        type="scatter",
        mode="lines",
        line=list(shape="spline"),
        name=~Nombre,
        showlegend=FALSE,
        text = ~paste("Nombre: ", Nombre,
                     "\nAño:", Yr,"\n",
                      format(round(ppm), nsmall=0,scientific=FALSE,big.mark=" "),
                      " por millón ",
                      sep=""),
        hoverinfo="all") %>% 
  layout(title="Evolución de los nombres más populares",
         yaxis = list(title="por millón de nacimientos",
                      fixedrange=FALSE),
         xaxis = list(title="Año",
                      fixedrange=FALSE)) 



######################################################
# Clusters de Nombres que varían Juntos           ####
# Para los 100 Nombres más populares de cada año  ####
######################################################


N100 <- PopularX(100)
H <- as.matrix(dcast(N100,Yr~Nombre,value.var="Total", fill=0)[,Yr:=NULL])
HC <- cor(H,H)

# Se utiliza la 1-correlación como la distancia para el clustering 
# Correlación -1 es distancia máxima (2)
# Correlación 1 es distancia mínima (0)
distances <- as.dist(1-HC)

Cluster <- pam(distances,8)
Cluster$clusinfo
ClusterTable <- data.table(Nombre =names(Cluster$clustering),
                           Cluster= as.factor(Cluster$clustering))
setkey(ClusterTable,Nombre)


# Agrega el número de cluster a cada entrada de N100
N100[,Cluster:=ClusterTable[N100[,Nombre],Cluster]]
N100[,Cluster:=as.factor(Cluster)]
ClusterNames <- N100[,.(Nombres=list(.SD[,Nombre])),by=Cluster]
NamesLists <- ClusterNames[,Nombres]
NamesLists <- lapply(NamesLists,unique)
NamesLists <- lapply(NamesLists, paste, collapse=" ")
NamesLists <- lapply(NamesLists,strwrap,width=30)
NamesLists <- sapply(NamesLists,paste,collapse="\n")
ClusterNames <- data.table(Cluster=ClusterNames[,Cluster],Names=NamesLists)
setkey(ClusterNames,Cluster)
ClusterChart <- N100[,.(ppmc=sum(ppm)),by="Yr,Cluster"]
ClusterChart[,Text:=ClusterNames[J(ClusterChart[,Cluster]),Names]]
ClusterChart[,Text:=as.factor(Text)]


plot_ly(ClusterChart,
        x=~Yr,
        y=~ppmc,
        type="scatter",
        mode="lines",
        line=list(shape="spline"),
        name=~Text,
        showlegend=FALSE,
        hovertemplate ="Nombres",
        hoverinfo="all") %>% 
  layout(title="Grupos de Nombres que evolucionaron en conjunto",
         yaxis = list(title="por millón de nacimientos",
                      fixedrange=FALSE),
         xaxis = list(title="Año",
                      fixedrange=FALSE)) 

