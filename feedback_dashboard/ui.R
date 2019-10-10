
library(DT)

navbarPage(title = "Unsupervised processing of patient feedback data",
           
           tabPanel("Topics",
                    fluidRow(
                      column(4, 
                             htmlOutput("showReactive")
                      ),
                      column(8, plotOutput("treeMap", height = "600px", width = "800px",
                                           click = "tClick")))
                    # fluidRow(DTOutput("showClick"))
           )
           # tabPanel("Sentiment",
           #          fluidRow(
           #            column(3, textOutput("beeswarmText")),
           #            column(9, plotOutput("beeswarmComments", click = "beeswarm_click")))
           # )
)
