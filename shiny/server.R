options(encoding = "UTF-8")
library(shiny)
library(data.table)


# Funciones Axiliares

# Importa las Variables con los Datos Necesarios
load("NC.RVar")
load("NSp.RVar")

# Años mínimos y máximos usando data.table
YrMin <- NC[,min(Yr)]
YrMax <- NC[,max(Yr)]

# Total de Inscriptos y Nombres simples en años y clase
TI <- NC[,.(YrTotal=sum(N)),keyby=Yr]
TI[,YrSimple:=NSp[,.(YrSimple=sum(NameYrTotal)),keyby=Yr][,YrSimple]]
TI[,ClassTotal:=frollsum(YrTotal,n=2,align="left",fill=TI[J(YrMax),YrTotal])]
TI[,ClassSimple:=frollsum(YrSimple,n=2,align="left",fill=TI[J(YrMax),YrSimple])]


# Función que devuelve el texto con las posibilidades a partir de las dos listas de nombres

############################################################
#   Probabilidad de haber sido de una clase particular     #
#   Si tuviste compañeros llamados ....                    #
############################################################

probableYears <- function(Simples, Completos){
  
    # Solución provisoria hasta que se eliminen los nombres vacíos de la base de datos
    Completos <- Completos[Completos !=""]  
    Simples <- Simples[Simples!=""]
      
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
    # TODO: Corregir cuando se corrija en el principal        #
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
     
    # Devuelve los años que suman el 90%
    setorder(PBA,PBA)[,Acum:=cumsum(.SD$PBA)]
    setorder(PBA,Yr)
    ToPrint <- PBA[Acum>10,paste("Clase ",Yr,"-",Yr+1,":",signif(PBA,digits=3),"%\n",sep="")]
    ToPrint <- paste(">90% de Probabilidades en los años:\n", paste(ToPrint,collapse=""),sep="")
    ToPrint
} # Fin función probableYears



# Separa el campo de texto en nombres individuales
splitNames <- function(x){A <- unlist(strsplit(x,"\n"))
                          ifelse(length(A)==0,A <-"",A <- A)
                          A
                        }



# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    
    Sn <- reactive({splitNames(input$Nombres_Simples)})
    Cn <- reactive({splitNames(input$Nombres_Completos)})
    output$simpleTextOut <- renderText(paste(Sn(),collapse="\n"))
    output$complexTextOut <- renderText(paste(Cn(),collapse="\n"))
    output$pYears <- renderText(probableYears(Sn(),Cn()))
})

