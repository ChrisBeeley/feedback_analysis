
navbarPage(title = "Unsupervised processing of patient feedback data",
           
           tabPanel("Topics",
               fluidRow(
                   column(3, htmlOutput("showReactive")),
                   column(9, plotOutput("treeMap", height="600px",
                                        click="click_treemap_country")))
           ),
           tabPanel("Sentiment",
                    fluidRow(
                        column(3, textOutput("beeswarmText")),
                        column(9, plotOutput("beeswarmComments", click = "beeswarm_click")))
                    )
)
