
# data and package loads----

# some code borrowed from here https://datascience-enthusiast.com/R/R_shiny_Tableau_treemap.html

library(feather)
library(tidyverse)
library(lubridate)
library(treemapify)

main_data <- read_feather("vader.feather") %>% 
    mutate(Date = floor_date(as.Date(Date))) %>% 
    mutate(pos_neg = case_when(
        sentiment < 0.2 ~ "neg",
        sentiment >= 0.2 ~ "pos")) %>% 
    select(Date, Keep_Improve, topic, sentiment, pos_neg)

topics <- read_feather("topics.feather") %>% 
    mutate(topic_number = row_number() - 1)

# join them together

main_data <- main_data %>% 
    left_join(topics, by = c("topic" = "topic_number"))

# shiny server----

function(input, output) {
    
    # data
    
    treemapData <- reactive({
        
        frequencies <- main_data %>% 
            group_by(words, pos_neg) %>% 
            count()
    })
    
    output$treeMap <- renderPlot({
        
        ggplot(frequencies, aes(area = n,
                       fill = words, subgroup = pos_neg)) + geom_treemap()
        
        #, 
                       # subgroup=YEAR))
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
    
    output$showNearPoints <- renderText({
        
        nearPoints()
    })
    
}