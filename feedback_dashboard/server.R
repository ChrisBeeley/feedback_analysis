
# some code borrowed from here https://datascience-enthusiast.com/R/R_shiny_Tableau_treemap.html

library(gridBase)
library(feather)
library(tidyverse)
library(treemap)

main_data <- read_feather("topic_modelled.feather") %>% 
    select(Keep_Improve, topic)

topics <- read_feather("topics.feather") %>% 
    mutate(topic_number = row_number() - 1)

# join them together

main_data <- main_data %>% 
    left_join(topics, by = c("topic" = "topic_number"))

frequencies <- main_data %>% 
    group_by(words) %>% 
    count()

### Handle cliks on a treemap
tmLocate <-
    function(coor, tmSave) {
        tm <- tmSave$tm
        
        # retrieve selected rectangle
        rectInd <- which(tm$x0 < coor[1] &
                             (tm$x0 + tm$w) > coor[1] &
                             tm$y0 < coor[2] &
                             (tm$y0 + tm$h) > coor[2])
        
        return(tm[rectInd[1], ])
        
    }

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    
    output$treeMap <- renderPlot({
        
        # par(mar=c(0,0,0,0), xaxs='i', yaxs='i') 
        # plot(c(0,1), c(0,1),axes=F, col="white")
        vps <- baseViewports()
        
        .tm <<- treemap(frequencies,
                        index="words",
                        vSize="n",
                        type="index"
        )
    })
    
    treemap_clicked_country <- reactiveValues(
        center = NULL,
        for_condition = NULL
    )
    
    # Handle clicks on treemap by country
    observeEvent(input$click_treemap_country, {
        x <- input$click_treemap_country$x
        y <- input$click_treemap_country$y
        treemap_clicked_country$center <- c(x,y)
        
        if(is.null(treemap_clicked_country$for_condition)){
            treemap_clicked_country$for_condition=c(x,y)
        }
        else{treemap_clicked_country$for_condition=NULL}
    })
    
    getRecord_population_country <- reactive({
        x <- treemap_clicked_country$center[1]
        y <- treemap_clicked_country$center[2]
        
        x <- (x - .tm$vpCoorX[1]) / (.tm$vpCoorX[2] - .tm$vpCoorX[1])
        y <- (y - .tm$vpCoorY[1]) / (.tm$vpCoorY[2] - .tm$vpCoorY[1])
        
        
        l <- tmLocate(list(x=x, y=y), .tm)
        z=l[, 1:(ncol(l)-5)]

        if(is.na(z[, 1])){
            return(NULL)
        }

        col = as.character(z[,1])
        
        return(col)
    })
    
    output$showReactive <- renderText({
        
        comment_selection <- main_data %>% 
            filter(words == getRecord_population_country()) %>% 
            sample_n(10) %>% 
            pull(Keep_Improve)
        
        paste("<p>", comment_selection, "</p>")
    })
})
