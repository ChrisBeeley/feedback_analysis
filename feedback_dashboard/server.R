
# data and package loads----

# some code borrowed from here https://datascience-enthusiast.com/R/R_shiny_Tableau_treemap.html

library(gridBase)
library(feather)
library(tidyverse)
library(treemap)
library(lubridate)

main_data <- read_feather("topic_modelled.feather") %>% 
    select(Keep_Improve, topic)

topics <- read_feather("topics.feather") %>% 
    mutate(topic_number = row_number() - 1)

sentiment <- read_feather("vader.feather") %>% 
    mutate(Date = floor_date(as.Date(Date)))

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

# shiny server----

function(input, output) {
    
    # topic treemap----
    
    output$treeMap <- renderPlot({
        
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
        
        validate(
            need(input$click_treemap_country, "Click a topic for example comments")
        )
        
        comment_selection <- main_data %>% 
            filter(words == getRecord_population_country()) %>% 
            sample_n(10) %>% 
            pull(Keep_Improve)
        
        paste("<p>", comment_selection, "</p>")
    })
    
    # sentiment tab----
    
    beeswarmGraph <- reactive({
        
        sentiment %>% 
            filter(!is.na(my_compound)) %>% 
            sample_n(100)
    })
    
    output$beeswarmComments <- renderPlot({
        
        beeswarmGraph() %>% 
            ggplot(aes(x = Date, y = my_compound)) + 
            geom_point() + 
            scale_colour_brewer(palette = "Spectral") + 
            theme(axis.text.x=element_text(angle = 45)) 
    })
    
    output$beeswarmText <- renderText({

        beeswarm_df <- nearPoints(beeswarmGraph(), input$beeswarm_click, threshold = 100, maxpoints = 1)
        
        validate(need(nrow(beeswarm_df) > 0, "Click a point to see the comment"))

        with(beeswarm_df, paste0(Keep_Improve, " (", Location, ")"))

    })
}
