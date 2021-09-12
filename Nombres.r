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


######################################################################
# TODO: Estandarizar nombre de variables                             #
#       Eliminar ppm y usar cantidades directamente                  #
######################################################################


# Carga los archivos como data.table ####

NC <- fread("Nombres_Completos.csv",
            encoding="UTF-8",key=c("Nombre","Yr"))

NS <- fread("Nombres_Simples.csv",
            encoding="UTF-8",key="Nombre")


###################################################
# Variables comunes a varios ejemplos             #
###################################################

# Años mínimos y máximos usando data.table
YrMin <- NC[,min(Yr)]
YrMax <- NC[,max(Yr)]

# Total de Inscriptos y Nombres simples en años y clase
TI <- NC[,.(YrTotal=sum(N)),keyby=Yr]
TI[,YrSimple:=NS[,.(YrSimple=sum(N)),keyby=Yr][,YrSimple]]
TI[,ClassTotal:=frollsum(YrTotal,n=2,align="left",fill=TI[J(YrMax),YrTotal])]
TI[,ClassSimple:=frollsum(YrSimple,n=2,align="left",fill=TI[J(YrMax),YrSimple])]


# Partes por millón de Nombres simples
NSp <- NS[,.(NameYrTotal=sum(N)),keyby="Nombre,Yr"]
NSp[,`:=`(ppm = NameYrTotal*1e6/TI[J(NSp[,Yr]),YrTotal],
          YrTotal =TI[J(NSp[,Yr]),YrTotal])]

# Partes por millón de Nombres Completos
NC[,`:=`(ppm=N*1e6/TI[J(NC[,Yr]),YrTotal],
    YrTotal =TI[J(NC[,Yr]),YrTotal])]

#####################################################
# Clases: El año Yr + el Año siguiente:             #
# Ejemplo Yr= 1980 => Clase Julio 1980 a Junio 1981 #
#####################################################

# Nombres Completos

    # Para los nombres que no aparecen el año anterior, se crea una entrada con valores en Cero para la cantidad
    NCNoAnt <- NC[Yr%in%(YrMin+1):YrMax&
                    (Nombre!=shift(Nombre,type="lag")|(Yr-1)!=shift(Yr,type="lag"))]
    NCNoAnt[,`:=`(ID=0,Yr=Yr-1,N=0,ppm=0)]
    NCNoAnt[,YrTotal:=TI[J(NCNoAnt[,Yr]),YrTotal]]
    
    NC <- rbindlist(list(NC,NCNoAnt))
    rm(NCNoAnt)
    setkey(NC,Nombre,Yr)
  
    # Copia los datos del año siguiente
    NC[,`:=`(YrTotal_1 = shift(YrTotal,type="lead",fill=0),
              N_1      = shift(N,type="lead",fill=0),
              Nombre_1 = shift(Nombre,type="lead",fill=0),
              Yr_1     = shift(Yr,type="lead",fill=YrMax)
              )]
    
    # Los nombres que no aparecen al año siguiente sólo se promedia con el total de los dos años como denominador
    NC[,NoNext:=(Nombre!=Nombre_1|Yr_1!=Yr+1)]
  
    NC[NoNext==TRUE, `:=`(YrTotal_1 = TI[J(pmin(NC[NoNext==TRUE,Yr]+1,YrMax)),YrTotal],
                          N_1       = 0)]
    
    
    # Calcula los totales de la Clase
    NC[,`:=`(ClassTotal = YrTotal+YrTotal_1,
             NClass     = N +N_1)]
    
    # Elimina las Columnas Intermedias y calcula ppm de la Clase
    NC[,`:=`(YrTotal_1=NULL,N_1=NULL,Nombre_1=NULL,Yr_1=NULL,NoNext=NULL,
              cppm =NClass*1e6/ClassTotal )]

    setkey(NC,ID)

# Nombres Simples

    # Para los nombres que no aparecen el año anterior, se crea una entrada con valores en Cero para la cantidad
    NSNoAnt <- NSp[Yr%in%(YrMin+1):YrMax&
                    (Nombre!=shift(Nombre,type="lag")|(Yr-1)!=shift(Yr,type="lag"))]
    NSNoAnt[,`:=`(Yr=Yr-1,NameYrTotal=0,ppm=0)]
    NSNoAnt[,YrTotal:=TI[J(NSNoAnt[,Yr]),YrTotal]]
    
    NSp <- rbindlist(list(NSp,NSNoAnt))
    rm(NSNoAnt)
    setkey(NSp,Nombre,Yr)
    
  
    # Copia los datos del año siguiente
    NSp[,`:=`(YrTotal_1     = shift(YrTotal,type="lead",fill=0),
              NameYrTotal_1 = shift(NameYrTotal,type="lead",fill=0),
              Nombre_1      = shift(Nombre,type="lead",fill=0),
              Yr_1          = shift(Yr,type="lead",fill=YrMax)
              )]
    
    # Los nombres que no aparecen al año siguiente sólo se promedia con el total de los dos años
    NSp[,NoNext:=(Nombre!=Nombre_1|Yr_1!=Yr+1)]
    
    NSp[NoNext==TRUE, `:=`(YrTotal_1     = TI[J(pmin(NSp[NoNext==TRUE,Yr]+1,YrMax)),YrTotal],
                           NameYrTotal_1 = 0)]
    
    # Calcula los totales de la Clase
    NSp[,`:=`(ClassTotal = YrTotal+YrTotal_1,
              NameClassTotal = NameYrTotal+NameYrTotal_1)]
    
    # Elimina las Columnas Intermedias y calcula ppm de la Clase
    NSp[,`:=`(YrTotal_1=NULL,NameYrTotal_1=NULL,Nombre_1=NULL,Yr_1=NULL,NoNext=NULL,
              cppm =NameClassTotal*1e6/ClassTotal )]
    

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


############################################################
#   Probabilidad de haber sido de una clase particular     #
#   Si tuviste compañeros llamados ....                    #
############################################################


Completos <- c("Nestor Fabio Damian")
# Primero las fracciones de todos los nombres como columnas, después los multiplica y se queda con la multiplicación 
# y al final pone en el listado de total de años siendo cero donde no hay ninguno

if (length(Completos)==0){
  ProbC <- data.table(Yr=YrMin:YrMax,ProbC=1,key="Yr")
}else{
  ProbC <- dcast(NC[Nombre%in%Completos],Yr~Nombre,fill=0, fun=sum,value.var="NClass")
  ProbC <- ProbC[,ProbC:=apply(.SD,1,prod),keyby=Yr][,.(Yr,ProbC)]
  ProbC <- merge(TI,ProbC,all.x=TRUE,by="Yr")[is.na(ProbC),ProbC:=0]
  ProbC[,ProbC:=ProbC*ClassTotal^(-length(Completos))]
}

Simples <- c("Gabriela", "Silvina", "Daniel", "Verónica",
             "Laura", "Cecilia", "Nestor", "Ricardo", "Karina", "Carina" )

if (length(Simples)==0){
  ProbS <- data.table(Yr=YrMin:YrMax,ProbS=1,key="Yr")
}else{
  ProbS <- dcast(NSp[Nombre%in%Simples],Yr~Nombre,fill=0, fun=sum,value.var="NameClassTotal")
  ProbS <- ProbS[,ProbS:=apply(.SD,1,prod),keyby=Yr][,.(Yr,ProbS)]
  ProbS <- merge(TI,ProbS,all.x=TRUE,by="Yr")[is.na(ProbS),ProbS:=0]
  ProbS[,ProbS:=ProbS*ClassSimple^(-length(Simples))]
}


## Bayes

###########################################################
# TODO: Hay un error conceptual en dividir por total de   #
# nombres simples para calcular la probabilidad y despues #
# ponderlos por el total de nombres completos. El efecto  #
# es mínimo porque la relación Nombres Simples / Nombre   #
# completo se mantiene históricamente en alrededor de 2   #
###########################################################

#P (A|B) = ProbT
ProbT <- merge(ProbS,
               ProbC[,`:=`(YrTotal =NULL,
                           YrSimple=NULL,
                           ClassTotal=NULL,
                           ClassSimple=NULL)
                     ],
               by="Yr")[,ProbT:=ProbS*ProbC]

#P(A) ó probabilidad de haber tenido esa combinación en el total de los años
PA <- sum(ProbT[,ProbT*ClassTotal/sum(.SD$ClassTotal)])

# P(B) ó probabilidad de que un nombre al azar sea de una clase en particular
PB <- ProbT[,ClassTotal/sum(.SD$ClassTotal)]

# Probabilidades Porcentuales
PBA <- ProbT[,.(Yr=Yr,PBA=ProbT*PB*100/PA)]

# Imprime los años que suman el 90%
setorder(PBA,PBA)[,Acum:=cumsum(.SD$PBA)]
setorder(PBA,Yr)
ToPrint <- PBA[Acum>10,paste("Clase ",Yr,"-",Yr+1,":",signif(PBA,digits=3),"%\n",sep="")]
ToPrint <- paste("90% de Probabilidades en los años:\n", paste(ToPrint,collapse=""),sep="")
cat(ToPrint)

#Limpieza
rm(Completos, Simples, ProbC, ProbS,ProbT, PA, PB, PBA, ToPrint)

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

# Divide en N Clusters
Cluster <- pam(distances,11)
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
  layout(title="Nombres por Época en Argentina",
         yaxis = list(title="Por millón de nacimientos",
                      fixedrange=FALSE),
         xaxis = list(title="Año",
                      fixedrange=FALSE)) 

#Limpieza
rm(N100,H,distances,Cluster,ClusterTable,ClusterNames)
