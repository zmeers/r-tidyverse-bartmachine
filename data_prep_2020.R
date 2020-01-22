##################################################
## Project: 2020 data prep
## Date: Thu Jan  9 08:36:17 2020
## Author: Zoe Meers
##################################################

library(tidyverse)
library(lubridate)
library(here)


fec_2020 <- read_csv("~/dropbox (sydney uni)/primaries/data/harry/fundraisingdemocrats2020.csv") %>% 
  mutate(as_of_date = gsub("(/19$)|(/2019$)", "\\/2019", as_of_date),
                           as_of_date = gsub("(/20$)|(/2020$)", "\\/2020", as_of_date)) %>% 
  mutate(as_of_date = lubridate::mdy(as_of_date)) %>% 
  mutate(primary_date = lubridate::ymd("2020-02-03")) %>% 
  rename(t_rev = days_to_iowa) %>% 
  group_by(true_name) %>% 
  complete(as_of_date = seq.Date(min(as_of_date), ymd(Sys.Date()), by = "day")) %>% 
  fill(contest, primary_date, raised, total_raised, fundraising) %>% 
  ungroup() %>% 
  mutate(t_rev = rep(seq(-60, interval(lubridate::ymd("2020-02-03"), ymd(Sys.Date())) %/% days(),by = 1), 
                 length(unique(true_name))) ) %>% 
  ungroup()

home_states_2020 <- tibble::tribble(
                            ~true_name,     ~home_state,
                     "Bernard Sanders",       "Vermont",
                    "Elizabeth Warren", "Massachusetts",
                      "Pete Buttigieg",       "Indiana",
                          "Tom Steyer",    "California",
                 "Joseph R. Biden Jr.",      "Delaware",
                        "John Delaney",      "Maryland",
                         # "Cory Booker",    "New Jersey",
                       "Amy Klobuchar",     "Minnesota",
                         "Andrew Yang",      "New York",
                       "Tulsi Gabbard",        "Hawaii",
                       # "Julian Castro",         "Texas",
                 # "Marianne Williamson",    "California",
                      "Michael Bennet",      "Colorado",
                   "Michael Bloomberg",      "New York",
                       "Deval Patrick", "Massachusetts"
                 )


load("dropboxsydneyuni/primaries/data/538/iowa_national_polls_538.rdata")

national_polls_2020 <- national_polls 

  
national_polls_2020_expand <- national_polls_2020 %>% 
  group_by(true_name) %>% 
  summarise(t_rev = min(t_rev)) %>% 
  mutate(days_out_today = interval(ymd("2020-02-03"), ymd(Sys.Date())),
         days_out_today = days_out_today %/% days(1)) %>% 
  group_by(true_name) %>% 
  complete(t_rev = seq(t_rev[1], days_out_today, by = 1)) %>% 
  ungroup() %>% 
  fill(days_out_today, .direction = "down") %>% 
  left_join(national_polls_2020) %>% 
  fill(everything(), .direction = "down")

iowa_polls_2020 <- iowa_polls 

iowa_polls_2020_expand <- iowa_polls_2020 %>% 
  group_by(true_name) %>% 
  summarise(t_rev = min(t_rev)) %>% 
  mutate(days_out_today = interval(ymd("2020-02-03"), ymd(Sys.Date())),
         days_out_today = days_out_today %/% days(1)) %>% 
  group_by(true_name) %>% 
  complete(t_rev = seq(t_rev[1], days_out_today, by = 1)) %>% 
  ungroup() %>% 
  fill(days_out_today, .direction = "down") %>% 
  left_join(national_polls_2020) %>% 
  fill(everything(), .direction = "down")

endorsements_2020 <- endorsement_points

drop_out_dates_2020  <- national_polls_2020 %>% 
  distinct(true_name) %>% 
  add_row(true_name = "Richard Neese Ojeda") %>% 
  mutate(date_left_race = NA_character_) %>% 
  mutate(date_left_race = case_when(
    true_name == "Julian Castro" ~  "2020-01-02",
    true_name == "Marianne Williamson" ~ "2020-01-10",
    true_name == "Kamala Harris" ~ "2019-12-03",
    true_name == "Beto O'Rourke" ~ "2019-11-01",
    true_name == "Wayne Messam" ~ "2019-11-21",
    true_name == "Tim Ryan" ~ "2019-10-24",
    true_name == "Steve Bullock" ~ "2019-12-02",
    true_name == "Joe Sestak" ~ "2019-12-01",
    true_name == "Bill de Blasio" ~ "2019-09-20",
    true_name == "Kirsten Gillibrand" ~ "2019-08-28",
    true_name == "Seth Moulton" ~ "2019-08-23",
    true_name == "John Hickenlooper" ~ "2019-08-15",
    true_name == "Jay Inslee" ~ "2019-08-21",
    true_name == "Eric Swalwell" ~ "2019-07-09",
    true_name == "Mike Gravel" ~ "2019-08-06",
    true_name == "Richard Neese Ojeda" ~ "2019-01-26",
    true_name ==  "Cory Booker" ~ "2020-01-14",
    TRUE ~ NA_character_
  ),
  date_left_race = ymd(date_left_race)) %>% 
  arrange(date_left_race)
  
save(iowa_polls_2020, national_polls_2020, 
     drop_out_dates_2020,
     iowa_polls_2020_expand, national_polls_2020_expand, 
     home_states_2020, endorsements_2020, fec_2020,
     file = "~/dropbox (sydney uni)/primaries/data/data_for_2020_preds.rdata")




