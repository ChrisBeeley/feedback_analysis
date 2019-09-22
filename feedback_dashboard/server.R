
# data and package loads----

# some code borrowed from here https://datascience-enthusiast.com/R/R_shiny_Tableau_treemap.html

library(feather)
library(tidyverse)
library(lubridate)
library(treemapify)
library(DT)
library(scales)

# from https://gist.github.com/Jfortin1/72ef064469d1703c6b30

lighten <- function(color, factor = 1.4){
    col <- col2rgb(color)
    col <- col*factor
    col <- rgb(t(as.matrix(apply(col, 1, function(x) if (x > 255) 255 else x))), maxColorValue = 255)
    col
}

main_data <- read_feather("vader.feather") %>% 
    mutate(Date = floor_date(as.Date(Date))) %>% 
    mutate(pos_neg = case_when(
        sentiment < -.2 ~ "neg",
        sentiment >= 0.3 ~ "pos",
        TRUE ~ NA_character_)) %>% 
    filter(!is.na(pos_neg)) %>% 
    select(Date, Keep_Improve, topic, sentiment, pos_neg)

topics <- read_feather("topics.feather") %>% 
    mutate(topic_number = row_number() - 1)

# join them together

main_data <- main_data %>% 
    left_join(topics, by = c("topic" = "topic_number"))

frequencies <- main_data %>% 
    group_by(words, pos_neg) %>% 
    count()

dark_colours <- viridis_pal()(10)
light_colours <- sapply(dark_colours, lighten)

frequencies$colour = NA

frequencies$colour[as.numeric(rownames(frequencies)) %% 2 == 0] <- light_colours
frequencies$colour[as.numeric(rownames(frequencies)) %% 2 == 1] <- dark_colours

# shiny server----

function(input, output) {
    
    # data
    
    treemapData <- reactive({
        
        frequencies <- main_data %>% 
            group_by(words, pos_neg) %>% 
            count()
    })
    
    output$treeMap <- renderPlot({
        
        tmapPlot()        
    })
    
    tmapCoords <- function() {
        treemapify(frequencies, area = "n", subgroup = "words", subgroup2 = "pos_neg")
    }
    
    tmapPlot <- function() {
        
        p <- ggplot(frequencies,
                    aes(area = n, subgroup = words, subgroup2 = pos_neg, label = words, fill = colour)) +
            geom_treemap(show.legend = FALSE) + geom_treemap_text(reflow = TRUE, place = "centre") +
            geom_treemap_subgroup2_text(place = "topleft", alpha = .5)
        
        
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
        
        comment_selection <- main_data %>%
            filter(words == topic_selected$words, 
                   pos_neg == topic_selected$pos_neg) %>% 
            arrange(sentiment) %>% 
            sample_n(10) %>%
            pull(Keep_Improve)
        
        paste("<p>", comment_selection, "</p>")
    })
    
    output$showClick <- renderDT({
        
        tmapCoords() %>%
            filter(xmin <= input$tClick$x) %>%
            filter(xmax >= input$tClick$x) %>%
            filter(ymin <= input$tClick$y) %>%
            filter(ymax >= input$tClick$y)
    })
    
    output$textView <- renderUI({
        
        validate(
            need(input$tClick, "Click a topic for example comments")
        )
        
        topic_selected <- tmapCoords() %>%
            filter(xmin <= input$tClick$x) %>%
            filter(xmax >= input$tClick$x) %>%
            filter(ymin <= input$tClick$y) %>%
            filter(ymax >= input$tClick$y)
        
        if(topic_selected$pos_neg == "pos"){
            
            tagList(
                h3("Positive comments are shown sorted from least to most positive"), 
                htmlOutput("showReactive")
            )
        } else {
            
            tagList(
                h3("Negative comments are shown sorted from most to least negative"),
                htmlOutput("showReactive")
            )
        }
    })
}

