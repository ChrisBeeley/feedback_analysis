
# Define UI for application that draws a histogram
shinyUI(fluidPage(

    # Application title
    titlePanel("Treemap"),

    sidebarLayout(
        sidebarPanel(
            htmlOutput("showReactive")
        ),

        # Show a plot of the generated distribution
        mainPanel(
            plotOutput("treeMap", height="600px",
                       click="click_treemap_country")
        )
    )
))
