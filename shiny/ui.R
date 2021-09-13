library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(

    # Application title
    titlePanel("Nombres en Argentina"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
          tags$div(tags$h4("Nombres Simples"),
              textAreaInput("Nombres_Simples","Uno por Línea", height="100%")),
          tags$div(tags$h4("Nombres Completos"),
               textAreaInput("Nombres_Completos", "Uno por línea", height="100%"))
          ),

        # Show a plot of the generated distribution
        mainPanel(
            tags$div(tags$h4("Nombres Simples Utilizados"),
                verbatimTextOutput("simpleTextOut")),
        tags$div(tags$h4("Nombres Completos Utilizados"),
            verbatimTextOutput("complexTextOut")),
        tags$div(tags$h4("Probabilidades"),
                 verbatimTextOutput("pYears")),
        )
    )
))
