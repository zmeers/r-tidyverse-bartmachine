##################################################
## Project: Nowcasting with 538 data
## Date: Fri Dec  6 11:42:45 2019
## Author: Zoe Meers
##################################################

library(lubridate)
library(tidyverse)
library(here)
library(rvest)
library(janitor)
library(ussc)


## load historical polling data
load(here::here("data/primary_polls_1984-2016.rdata"))

# grab current data from 538

# load primary calendar
load(here::here("data/primary_calendar.RData"))

primary_calendar <- primary_calendar %>% 
  filter(!str_detect(primary_caucus, "Rep")) %>% 
  mutate(primary_caucus = gsub(" Democratic", "", primary_caucus),
         primary_caucus = gsub(" If.*", "", primary_caucus)) %>% 
  separate(primary_caucus, c("state","primary_caucus"),sep = ' (?=[^ ]+$)') %>% 
  rename(election_date = date) %>% 
  select(election_date, state) %>% 
  add_row(election_date = ymd("2020-11-03"), state = "National")

primary_polls <- read_csv("https://projects.fivethirtyeight.com/polls-page/president_primary_polls.csv") %>% 
  filter(party == "DEM") %>% 
  mutate(state = replace_na(state, "National"),
         contest = "2020D",
         start_date = mdy(start_date),
         end_date = mdy(end_date),
         mid_date = start_date + floor((end_date-start_date)/2)) %>% 
  left_join(primary_calendar %>% select(election_date, state), by = "state") %>% 
  mutate(t = interval(mid_date, election_date),
         t = t %/% days(1),
         f = interval(start_date, end_date),
         field_time = f %/% days(1),
         t_rev = interval(election_date, mid_date),
         t_rev = t_rev %/% days(1)) %>% 
  select(-f) %>% 
  rename(share = pct) %>% 
  mutate(candidate_name = gsub("\\s[A-Z]\\.\\s", " ", candidate_name),
         candidate_name = gsub(" Robert", "", candidate_name),
         candidate_name = gsub("Joseph Biden Jr.", "Joseph R. Biden Jr.", candidate_name),
         candidate_name = gsub("á", "a", candidate_name)) %>% 
  rename(true_name = candidate_name) %>% 
  rename(last_name = answer) %>% 
  mutate(notes = replace_na(notes, "standard poll")) %>% 
  filter(!str_detect(notes, "head|open")) %>% 
  filter(question_id != 115625)

# check for head to heads or hypothetical questions

# list of actual candidates (current or past)
candidates <- tribble(~true_name, ~status,
                      "Michael Bennet", "running",
                      "Joseph R. Biden Jr.", "running",
                      "Bernard Sanders", "running",
                      "Elizabeth Warren", "running",
                      "Michael Bloomberg", "running",
                      "Cory Booker", "dropped out",
                      "Pete Buttigieg", "running",
                      "John Delaney", "running",
                      "Tulsi Gabbard", "running",
                      "Amy Klobuchar", "running",
                      "Deval Patrick", "running",
                      "Tom Steyer", "running",
                      "Andrew Yang", "running",
                      "Steve Bullock", "dropped out",
                      "Julian Castro", "dropped out",
                      "Bill de Blasio", "dropped out",
                      "Kirsten Gillibrand", "dropped out",
                      "Kamala Harris", "dropped out",
                      "John Hickenlooper", "dropped out",
                      "Jay Inslee", "dropped out",
                      "Wayne Messam", "dropped out",
                      "Seth Moulton", "dropped out",
                      "Richard Neece Ojeda", "dropped out",
                      "Beto O'Rourke", "dropped out",
                      "Tim Ryan", "dropped out",
                      "Joe Sestak", "dropped out",
                      "Eric Swalwell", "dropped out",
                      "Marianne Williamson", "dropped out")

# grab a list of poll ids that include someone NOT in the list above

primary_polls_tmp <- primary_polls %>%
  group_by(true_name) %>% 
  summarise(poll_ids  = paste(poll_id, collapse =","), 
            times = length(poll_id))  %>%
  arrange(times) %>% 
  ungroup() %>% 
  left_join(candidates) %>% 
  separate_rows(poll_ids, sep = ",") %>% 
  filter(is.na(status)) %>% 
  distinct(poll_ids)

length(primary_polls$poll_id)

pp <- primary_polls %>% 
  filter(!poll_id %in% primary_polls_tmp$poll_ids)

length(pp$poll_id)



# Looks good!!! 

primary_polls <- pp


endorsement_points <- read_csv("https://projects.fivethirtyeight.com/endorsements-2020-data/endorsements-2020.csv") %>% 
  arrange(endorsee, date) %>% 
  filter(category %in% c("Representatives", "Senators", "Governors")) %>%
  drop_na(endorsee) %>% 
  mutate(points = case_when(
    category == "Representatives" ~ 1,
    category == "Senators" ~ 5,
    category == "Governors" ~ 10
  )) %>% 
  select(date, endorsee, points) %>% 
  group_by(endorsee, date) %>% 
  summarise(points = sum(points)) %>% 
  ungroup() %>% 
  group_by(endorsee) %>% 
  mutate(cumulative_endorsement_points = cumsum(points)) %>% 
  ungroup() %>% 
  rename(endorsement_points = points) %>% 
  group_by(endorsee) %>% 
  complete(date = seq.Date(min(date), ymd(Sys.Date()), by = "day")) %>% #expand from first date to today
  fill(endorsement_points, .direction = "down") %>% 
  fill(cumulative_endorsement_points, .direction = "down") %>% 
  ungroup() %>% 
  mutate(primary_date = ymd("2020-02-03"),
         contest = "2020D") %>% 
  mutate(t_rev = interval(primary_date, date),
         t_rev = t_rev %/% days(1)) %>% 
  rename(as_of_date = date) %>% 
  mutate(max_endorsement_points = 707, 
         perc_max_endorsement_points = (cumulative_endorsement_points/max_endorsement_points)*100) %>% 
  select(contest, as_of_date, t_rev, true_name = endorsee, endorsement_points = max_endorsement_points, 
         max_points_possible = max_endorsement_points, percent_max_points = perc_max_endorsement_points, primary_date) %>% 
  mutate(true_name = case_when(
    true_name == "Bernie Sanders" ~ "Bernard Sanders",
    true_name == "Joe Biden" ~ "Joseph R. Biden Jr.",
    TRUE ~ true_name
  )) 



primary_polls_538 <- primary_polls

save(primary_polls_538, file  = here::here("data/538/primary_polls_538.rdata"))

iowa_nat <- primary_polls_538 %>% 
  filter(str_detect(state, 'Iowa|National')) %>% # change national date to iowa date, recalculate t_rev
  mutate(election_date = case_when(
    election_date == ymd("2020-11-03") ~ ymd("2020-02-03"),
    TRUE ~ election_date
  )) %>% 
  mutate(t_rev = interval(election_date, mid_date),
         t_rev = t_rev %/% days(1)) %>% 
  rename(primary_date = election_date) %>% 
  select(-t)
  

iowa_polls <- iowa_nat %>% 
  filter(state == "Iowa")

iowa_polls %>% 
  distinct(true_name) %>%  
  print(n = Inf)

national_polls <-  iowa_nat %>% 
  filter(state == "National")

national_polls %>% 
  distinct(true_name) %>%  
  print(n = Inf)

save(iowa_polls, national_polls, iowa_nat, primary_polls_538, 
     endorsement_points, candidates,
     file  = here::here("data/538/iowa_national_polls_538.rdata"))



saveRDS(iowa_polls, file  = here::here("data/538/iowa_primary_2020_538.rds"))

saveRDS(national_polls, file  = here::here("data/538/national_2020_538.rds"))

