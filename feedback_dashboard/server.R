
# data and package loads----

# some code borrowed from here https://datascience-enthusiast.com/R/R_shiny_Tableau_treemap.html

library(feather)
library(tidyverse)
library(lubridate)
library(treemapify)
library(DT)
library(scales)
library(RColorBrewer)

# from https://gist.github.com/Jfortin1/72ef064469d1703c6b30

lighten <- function(color, factor = 1.4){
    col <- col2rgb(color)
    col <- col*factor
    col <- rgb(t(as.matrix(apply(col, 1, function(x) if (x > 255) 255 else x))), maxColorValue = 255)
    col
}

colfunc<-colorRampPalette(c("red","green"))

text_colours <- colfunc(4)

main_data <- read_feather("../topic_modelled.feather") %>% 
    mutate(pos_neg = case_when(
        sentiment < -.2 ~ "neg",
        sentiment >= 0.3 ~ "pos",
        TRUE ~ NA_character_)) %>% 
    filter(!is.na(pos_neg)) %>% 
    filter(Improve != "No comment", Improve != "no comment") %>% 
    mutate(text_colour = case_when(
        sentiment <= -.5 ~ text_colours[1],
        sentiment < 0 ~ text_colours[2],
        sentiment < 0.5 ~ text_colours[3],
        TRUE ~ text_colours[4]
    )) %>%
    mutate(text_category = case_when(
        sentiment <= -.5 ~ "Very negative",
        sentiment < 0 ~ "Slightly negative",
        sentiment < 0.5 ~ "Slightly positive",
        TRUE ~ "Very positive"
    )) %>%
    select(Improve, topic, sentiment, pos_neg, text_colour, text_category)

topics <- read_feather("../topics.feather") %>% 
    mutate(topic_number = row_number() - 1)

# join them together

main_data <- main_data %>% 
    left_join(topics, by = c("topic" = "topic_number"))

dark_colours <- viridis_pal()(10)

# shiny server----

function(input, output) {
    
    # data
    
    treemapData <- reactive({
        
        frequencies <- main_data %>% 
            group_by(words) %>% 
            count()
    })
    
    output$treeMap <- renderPlot({
        
        tmapPlot()        
    })
    
    tmapCoords <- function() {
        treemapify(treemapData(), area = "n", subgroup = "words")
    }
    
    tmapPlot <- function() {
        
        p <- ggplot(treemapData(),
                    aes(area = n, subgroup = words, label = words, fill = dark_colours)) +
            geom_treemap(show.legend = FALSE) + geom_treemap_text(reflow = TRUE, place = "centre")

        return(p)
    }
    
    output$showReactive <- renderText({
        
        validate(
            need(input$tClick, "Click a topic for example comments")
        )
        
        topic_selected <- tmapCoords() %>%
            filter(xmin <= input$tClick$x) %>%
            filter(xmax >= input$tClick$x) %>%
            filter(ymin <= input$tClick$y) %>%
            filter(ymax >= input$tClick$y)
        
        # filter the data so there is a mix of categories
        
        filter_data <- main_data %>% 
            filter(words == topic_selected$words) %>% 
            group_by(text_category) %>% 
            sample_n(ifelse(n() >= 5, 5, n())) %>%
            ungroup() %>% 
            select(Improve, text_category)
        
        finalText = map(c("Very negative", "Slightly negative", "Slightly positive", "Very positive"), function(x) {
            
            commentsFrame = filter_data %>% 
                filter(text_category == x) %>% 
                ungroup() %>% 
                select(Improve)
            
            paste0("<h3>", x, "</h3>", 
                   paste0("<p>", commentsFrame$Improve, "</p>", collapse = "")
            )
        })
        
        return(unlist(finalText))
    })
}

