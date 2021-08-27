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

###################################################
# Variables comunes a varios ejemplos             #
###################################################

# Total de Inscriptos en un año
TI <- NC[,.(YrTotal=sum(N)),keyby=Yr]     

# Partes por millón de Nombres simples
NSp <- NS[,.(NameYrTotal=sum(N)),keyby="Nombre,Yr"]
NSp[,`:=`(ppm = NameYrTotal*1e6/TI[J(NSp[,Yr]),YrTotal],
          YrTotal =TI[J(NSp[,Yr]),YrTotal])]

# Partes por millón de Nombres Completos
NC[,ppm:=N*1e6/TI[J(NC[,Yr]),YrTotal]]


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

# Limpieza
rm(A,AN,CN,ListaNombres)


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

#Limpieza
rm(ListaNombres,B)


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

# Limpieza
rm (A, AN, B, BN, C, CN, D, Caption, Title)

##########################################
# 20 Nombres más populares de un  año ####
##########################################

Año = 1997
NCi <- NSp[Yr==Año]
NCi <- setorder(NCi,-NameYrTotal)[1:20,]
# Exportar sacando comentario de abajo
# write.csv(NCi, file = Popular20Yr.csv, row.names=FALSE,fileEncoding = "UTF-8")

G <- ggplot(NCi)+
  geom_bar(aes(x=reorder(Nombre,-NameYrTotal),
               y=NameYrTotal,
               fill=NameYrTotal),
           stat="identity")+
  labs(x="Nombre", y="Cantidad",
         title=paste("20 Nombres más populares del año ",Año,sep=""))+
  theme_minimal()+
  theme(axis.text.x = element_text(angle=90, hjust=1, vjust=0.5))
plot(G)
  
rm(Año, NCi)


###########################
#  Total de Inscriptos ####
###########################

G <- ggplot(TI) + 
    geom_point(aes(x=Yr,y=YrTotal/1e6))+
    geom_line(aes(x=Yr,y=YrTotal/1e6))+
    theme_minimal()+
    labs(title="Número de nombres inscriptos por año",
           x="Año",
           y="Millones") +
    scale_x_continuous(breaks = seq(1920,2020,10))
plot(G)


##########################################################
# Función X Nombres simples más populares de cada año ####
##########################################################

PopularX <- function(N_Popular, exclude=c("Del","Los","De")){
  
    # Selección de los 20 mayores de cada año que no estén en los excluidos  
    XPop <- NSp[!Nombre%in%exclude,
                last(.SD[order(NameYrTotal)],N_Popular),
                by=Yr]

    # Se recalculan todos los que algunas vez fueron top de un año para todos los años
    XPop <- NSp[Nombre%chin%XPop[,Nombre]]
        
}
    
    
    
############################################################    
# Tabla de 20 Nombres Más Populares por año para exportar  #
############################################################
# NCtw <- dcast(PopularX(20),Yr~Nombre,value.var="NameYrTotal", fill=0)
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
#Limpieza
rm(NCht)


######################################################
# Clusters de Nombres que varían Juntos           ####
# Para los 100 Nombres más populares de cada año  ####
######################################################


N100 <- PopularX(100)
H <- as.matrix(dcast(N100,Yr~Nombre,value.var="NameYrTotal", fill=0)[,Yr:=NULL])

# Se utiliza la 1-correlación como la distancia para el clustering 
# Correlación -1 es distancia máxima (2)
# Correlación 1 es distancia mínima (0)
distances <- as.dist(1-cor(H,H))

Cluster <- pam(distances,8)
ClusterTable <- data.table(Nombre =names(Cluster$clustering),
                           Cluster=Cluster$clustering)
setkey(ClusterTable,Nombre)


# Agrega el número de cluster a cada entrada de N100
N100[,Cluster:=ClusterTable[N100[,Nombre],Cluster]]

#Plot

# Esta sección es para generar la lista de nombre con un ancho de 30
# Y que esa lista sea el índice de cada grupo (no el ID)

ClusterNames <- N100[,.(Nombres=list(.SD[,Nombre])),keyby=Cluster]
ClusterNames[,Nombres:=lapply(Nombres,unique)]
ClusterNames[,Nombres:=lapply(Nombres,paste,collapse=" ")]
ClusterNames[,Nombres:=lapply(Nombres,strwrap,width=30)]
ClusterNames[,Nombres:=sapply(Nombres,paste,collapse="\n")] # Un Vector por cluster

N100 <- N100[,.(ppmc=sum(.SD[,ppm])),keyby="Cluster,Yr"]
N100[,Text:=ClusterNames[J(N100[,Cluster]),Nombres]]
N100[,Text:=as.factor(Text)]


plot_ly(N100,
        x=~Yr,
        y=~ppmc,
        type="scatter",
        mode="lines",
        line=list(shape="spline"),
        name=~Text,
        showlegend=FALSE,
        hovertemplate ="Nombres",
        hoverinfo="all") %>% 
  layout(title="Nombres de Época",
         yaxis = list(title="por millón de nacimientos",
                      fixedrange=FALSE),
         xaxis = list(title="Año",
                      fixedrange=FALSE)) 

#Limpieza
rm(N100,H,distances,Cluster,ClusterTable,ClusterNames)
