library(shiny)
library(ggplot2)
library(dplyr)
library(rvest)
library(shinythemes)
library(ggrepel)

load("~/GitHub/final-project-houseelections/Shiny-App/data/tabcountry.Rdata")
load("~/GitHub/final-project-houseelections/Shiny-App/data/tabstate.Rdata")
load("~/GitHub/final-project-houseelections/houseelections/houseelections/data/Election_Data2.Rdata")



house_data <- Cleaned_House_Election_Results_States
house_data$District <- gsub('[0-9]', '', house_data$District)
house_data$District <- gsub('at-large', '', house_data$District)

#Import population by state data
pop_url <- "https://simple.wikipedia.org/wiki/List_of_U.S._states_by_population"
pop_page <- read_html(pop_url)
pop_tables <- html_table(html_nodes(pop_page, "table"), fill = TRUE)
pop_table <- pop_tables[[2]]

#Some light cleaning and relabeling
pop_table <- select(pop_table, 3,4)
pop_table <- pop_table[ -c(30,50,53:64), ]
colnames(pop_table)[colnames(pop_table)=="State or territory"] <- "State"
colnames(pop_table)[2] = "Population_Est"

#Remove commas from integers
pop_table[,2] = as.integer(gsub(",","",pop_table[,2]))

#Arrange by state
arranged_pop_table = pop_table %>% arrange(State)
arranged_pop_table$state_abbr <- c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY" )
#End for plot 3

# Define UI for application
ui <- navbarPage(theme = shinytheme("spacelab"), "House Elections: A Look at Historic Data and Social Determinants",
   
      # Show a plot of the generated state-specific bar
          tabPanel("Welcome", 
                  h4("Welcome to our app! Here, you can begin to explore historic
                        elections data from the U.S. House of Representatives as well as 
                        some healthcare access data from the Centers for Disease Control
                        and Prevention Behavioral Risk Factor Surveillance System.
                        In 'Visualizing Elections', you can look at election trends across
                        time. In 'Healthcare', you can look at how medical costs and race 
                        interact to influence healthcare access."),
                  img(src='map.png', align = "center", width = '50%', height = '50%')),
          tabPanel("Visualizing Elections",
                     sidebarLayout(
                       sidebarPanel(
                         sliderInput("year",
                                     "Election Years",
                                     min = 1998,
                                     max = 2016,
                                     value = 2002,
                                     step = 2,
                                     sep = ""
                         )
                       ),
                       mainPanel(
                         plotOutput("rep_count_plot") ,
                         plotOutput("state_party_plot"),
                         plotOutput("pop_state_2")))),

            tabPanel("Healthcare", 
                     # Sidebar with a dropdown input for filtering by state
                     sidebarLayout(
                       sidebarPanel(
                         selectInput("stateInput", "State",
                                     c("ALABAMA", "ALASKA", "ARIZONA", "ARKANSAS", "CALIFORNIA", 
                                       "COLORADO", "CONNECTICUT", "DELAWARE", "DISTRICT OF COLUMBIA", 
                                       "FLORIDA", "GEORGIA", "HAWAII", "IDAHO", "ILLINOIS", "INDIANA",
                                       "IOWA", "KANSAS", "KENTUCKY", "LOUISIANA", "MAINE", "MARYLAND",
                                       "MASSACHUSETTS", "MICHIGAN", "MINNESOTA", "MISSISSIPPI", 
                                       "MISSOURI", "MONTANA", "NEBRASKA", "NEVADA", "NEW HAMPSHIRE",
                                       "NEW JERSEY", "NEW MEXICO", "NEW YORK", "NORTH CAROLINA", 
                                       "NORTH DAKOTA", "OHIO", "OKLAHOMA", "OREGON", "PENNSYLVANIA",
                                       "RHODE ISLAND", "SOUTH CAROLINA", "SOUTH DAKOTA", "TENNESSEE",
                                       "TEXAS", "UTAH", "VERMONT", "VIRGINIA", "WASHINGTON",
                                       "WEST VIRGINIA", "WISCONSIN", "WYOMING", "GUAM", "PUERTO RICO",
                                       "U.S. VIRGIN ISLANDS"))),
                       
                       mainPanel(
                                h3("We chose to explore race and access to care state-by-state.
                                   To get this information, we analyzed a question from the 
                                   Behavioral Risk Factor Surveillance System."),
                                br(),br(),
                                h4("Was there a time in the past 12 months when you needed to see a 
                                   doctor but could not because of cost?"),
                                br(),br(), br(), br(),
                                plotOutput("statePlot"),
                                br(),br(), br(), br(),
                                plotOutput("countryPlot"),
                                br(),br(),
                                h4("The table below shows a chi-square test between race and 
                                   the influence of cost on access to care. Based on the extremely
                                   small p-value, the null hypothesis that there is no association
                                   between the two is rejected in favor of the null. Note R
                                   reported the p-value as 0.00 because it was so small. Any future analysis
                                   of the relationship would probably be best explored using 
                                   a logistic regression model."),
                                br(),br(),
                                tableOutput("chisq"))))
                            
                                
      )
  


# Define server logic required to draw a bar
server <- function(input, output) {

  output$statePlot <- renderPlot({

     tabstate <- tabstate %>%
        filter(state_name == input$stateInput, couldnt_see_doc_due_to_cost %in% c("yes", "no")) %>%
        group_by(race) %>%
        mutate(totalfreq = sum(Freq, na.rm = TRUE), proportion = Freq/totalfreq)

     ggplot(tabstate, aes(x = race, y = proportion, fill = forcats::fct_rev(couldnt_see_doc_due_to_cost))) +
       geom_col(position = "fill") +
       coord_flip() +
       ggtitle("State-specific") +
       theme(plot.title = element_text(hjust = 0.5)) +
       scale_fill_discrete(name = "Answer") +
       xlab("Race") +
       ylab("Proportion")
     
      })
  
  output$countryPlot <- renderPlot({
    
    tabcountry <- tabcountry %>%
      filter(couldnt_see_doc_due_to_cost %in% c("yes", "no")) %>%
      group_by(race) %>%
      mutate(totalfreq = sum(Freq, na.rm = TRUE), proportion = Freq/totalfreq)
    
    ggplot(tabcountry, aes(x = race, y = proportion, fill = forcats::fct_rev(couldnt_see_doc_due_to_cost))) +
      geom_col(position = "fill") +
      coord_flip() +
      ggtitle("United States") +
      theme(plot.title = element_text(hjust = 0.5)) +
      scale_fill_discrete(name = "Answer") +
      xlab("Race") +
      ylab("Proportion")
    
  })
  
  output$chisq <- renderTable({
    chisq_output
  })
  
  #year scale
  output$rep_count_plot <- renderPlot({
    house_data <-   house_data[[as.character(input$year)]] %>% 
      group_by(State, Winning_Party) %>%
      summarize(num = n())
    
    #plot 1
    ggplot(house_data, aes(State, num)) +
      theme_bw() +
      theme(axis.text.x = element_text(angle = 60, hjust = 1)) +
      scale_fill_manual(values = c("royalblue3", "red1", "grey")) + 
      scale_y_continuous(breaks = seq(0, 60, 10)) +
      geom_bar(stat = "identity", aes(fill = Winning_Party))
  })
  

  
  
  #plot 2
  output$state_party_plot <- renderPlot({
    state_party_majority <- house_data[[as.character(input$year)]] %>%
      group_by(State) %>%
      summarize(num_rep = sum(Winning_Party=="Republican",na.rm=TRUE),
                num_dem = sum(Winning_Party=="Democrat",na.rm=TRUE),
                total_rep = num_rep + num_dem) %>%
      group_by(State) %>%
      summarize(majority_party = num_dem - num_rep) %>%
      mutate(majority = ifelse(majority_party > 0, "majority_dem", "majority_rep"))
    
    ggplot(state_party_majority, aes(State, majority_party)) + 
      theme_bw()+
      theme(axis.text.x = element_text(angle = 60, hjust = 1)) +
      scale_fill_manual(values = c("royalblue3", "red1")) +
      scale_y_continuous(breaks = seq(0, 60, 10)) +
      geom_bar(stat = "identity", aes(fill = majority))
    
  })
  
  
  
  #plot 3
  output$pop_state_2 <- renderPlot({
    
    pop_state_2 <- Election_Data %>%
      filter(Election_Year == input$year) %>%
      
      #Consolidate districts into states and count number of representatives in each party
      group_by(State) %>%
      summarize(num_rep = sum(Winning_Party=="Republican",na.rm=TRUE),
                num_dem = sum(Winning_Party=="Democrat",na.rm=TRUE),
                total_rep = num_rep + num_dem) %>%
      
      #Column bind population to dem/rep count table
      arrange(State) %>%
      cbind(Population = arranged_pop_table[,2]) %>%
      cbind(Abbr = arranged_pop_table[,3])
    
    ggplot(pop_state_2 %>% mutate(pct_republican = num_rep/total_rep, majority = ifelse(pct_republican > 0.5, "majority_republican", "majority_democrat")), aes(Population, total_rep) ) +
      geom_point(size = 4, alpha = 0.5, aes(color = majority)) +
      scale_color_manual(values = c("blue", "red")) +
      geom_smooth(method=lm, se = FALSE) +
      geom_text_repel(aes(label = Abbr)) +
      #scale_x_log10() + #For readability
      theme_bw() 
  })
  
    }  
   

# Run the application 
shinyApp(ui = ui, server = server)

