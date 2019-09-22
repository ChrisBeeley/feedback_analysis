
library(DT)

navbarPage(title = "Unsupervised processing of patient feedback data",
           
           tabPanel("Topics",
                    fluidRow(
                      column(4, 
                             uiOutput("textView")),
                      column(7, plotOutput("treeMap", height = "600px",
                                           click = "tClick")))
                    # fluidRow(DTOutput("showClick"))
           )
           # tabPanel("Sentiment",
           #          fluidRow(
           #            column(3, textOutput("beeswarmText")),
           #            column(9, plotOutput("beeswarmComments", click = "beeswarm_click")))
           # )
)
