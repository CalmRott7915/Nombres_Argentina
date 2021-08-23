options(encoding = "UTF-8")
library(data.table)
library(ggplot2)


# Carga los archivos como data.table

NC <- fread("Nombres_Completos.csv",
            encoding="UTF-8")

NS <- fread("Nombres_Simples.csv",
            encoding="UTF-8")


# Keys
setkey(NS, Nombre)
setkey(NC,ID)


# Un conjunto de nombres (Cualquiera)
ListaNombres=c("Kevin","Brian","Johnatan","Jonatan","Bryan")
A <- NS[ListaNombres,.(Total=sum(N)),Yr]

#Plot
G <- ggplot(A)+
  geom_point(aes(x=Yr, y=Total))+
  geom_smooth(aes(x=Yr,y=Total),span=0.07,se=FALSE)+
  theme_light()+
  labs(x="Año",y="Total",
       title=paste("Evolución de los Nombres: ", paste(ListaNombres,collapse="/"),sep=""))
plot(G)


# Un Conjunto de Nombres Exactos
ListaNombres = c("Cristina Elizabeth","Néstor Carlos")
B <- NC[Nombre%in%ListaNombres,.(Total=sum(N)),Yr]

#Plot
G <- ggplot(B)+
  geom_point(aes(x=Yr, y=Total))+
  geom_smooth(aes(x=Yr,y=Total),span=0.07,se=FALSE)+
  theme_light()+
  labs(x="Año",y="Total",
       title=paste("Evolución de los Nombres: ", paste(ListaNombres,collapse="/"),sep=""))
plot(G)


# Tanto los nombres de A como de B en uno sólo
A <- c("Raul","Raúl")
B <- c("Ricardo")
AN <- NS[A]
setkey(AN,ID)
BN <- NS[B]
setkey(BN,ID)
C <- merge(AN,BN)

CN <- NC[J(C$ID),first(Nombre),keyby=Nombre][,.(Nombre)]
Caption <- paste(head(CN,15)[,Nombre], collapse="/")
Caption <- strwrap(Caption,width=80)
Caption <- paste(Caption, collapse = "\n")
Caption <- paste("Ejemplos:\n", Caption)

D <- C[,.(Total=sum(N.x)),.(Yr=Yr.x)]

#Plot
G <- ggplot(D)+
  geom_point(aes(x=Yr, y=Total))+
  geom_smooth(aes(x=Yr,y=Total),span=0.07,se=FALSE)+
  theme_light()+
  labs(x="Año",y="Total",
       title=paste("Evolución de los Nombres: ", paste(paste(A,collapse=" o "),
                                                       paste(B,collapse=" o "),
                                                       sep=" + ")),
       caption=Caption)
plot(G)


# 20 Nombres más populares de un  año
Año = 1970
NCi <- NS[Yr==Año,.(Total=sum(N)),by=Nombre]
NCi <- setorder(NCi,-Total)[1:20,]


#  Total de Inscriptos
TI <- NC[,.(Total=sum(N)),keyby=Yr]     
ggplot(TI) + geom_point(aes(x=Yr,y=Total/1e6))+
          geom_line(aes(x=Yr,y=Total/1e6))+
          theme_light()+
          labs(title="Número de nombres inscriptos por año",
                 x="Año",
                 y="Millones") +
          scale_x_continuous(breaks = seq(1920,2020,10))
