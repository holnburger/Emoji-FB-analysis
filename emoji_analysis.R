# most of the script written by Jessica Peterka-Bonetta
# check it out on https://github.com/today-is-a-good-day/emojis/blob/master/emoji_analysis.R
options(stringsAsFactors = FALSE)
library(dplyr)
library(stringr)
library(rvest)
library(Unicode)
library(tm)
library(base64enc)
library(RMySQL)
library(parallel)

## This is written for a system with minimum 5 cores.
# If you have less then five cores, edit the mc.cores values or delete them (back to default)
detectCores()

Sys.setlocale(category = "LC_ALL", locale = "en_US.UTF-8")

## ---- utility functions ----
# this function outputs the emojis found in a string as well as their occurences
count_matches <- function(string, matchto, description, sentiment = NA) {

  vec <- str_count(string, matchto)
  matches <- which(vec != 0)

  descr <- NA
  cnt <- NA

  if (length(matches) != 0) {

    descr <- description[matches]
    cnt <- vec[matches]

  }

  df <- data.frame(text = string, description = descr, count = cnt, sentiment = NA)

  if (!is.na(sentiment) & length(sentiment[matches]) != 0) {

    df$sentiment <- sentiment[matches]

  }

  return(df)

}

# this function applies count_matches on a vector o texts and outputs a data.frame
emojis_matching <- function(texts, matchto, description, sentiment = NA) {

  texts %>%
    mclapply(count_matches, matchto = matchto, description = description, sentiment = sentiment, mc.cores = 5) %>%
    bind_rows

}

# fill in your username, password…
# I stored the comments in a SQL-Database and extracted it from there
con <- dbConnect(MySQL(), user="user", password="password", dbname="dbname", host="localhost")

sqlset <- "SET NAMES utf8mb4"
do <- dbGetQuery(con,sqlset)

# This is my custom query. Mainly based on the structure given by the tab delimited file I got from netvizz
# I also added an Alias table with the clear name of the german parties instead of Facebook IDs
query <- dbSendQuery(con, "SELECT @n := @n + 1 commentID, c.comment_published AS \"created\", c.comment_message AS \"text\", c.comment_by AS \"username\", a.Partei, a.Richtung_Wirtschaft, a.Richtung_Politik FROM Alias a, All_comments c, (SELECT @n := 0) n WHERE c.post_by=a.Alt_Name AND a.Richtung_Politik=\"links\" AND c.comment_published BETWEEN \"2016-07-31\" AND \"2017-07-31\"")
fbcommentsraw <- dbFetch(query, n = -1)

# maybe cleanup the comments or build a subset, otherwise proceed with the whole dataset

fbcomments <- fbcommentsraw

# read in emoji dictionary
# I used to get the dictionary from Felipe: https://github.com/felipesua
# but he put it down, so I uploaded the csv file to my github profile:
# https://raw.githubusercontent.com/today-is-a-good-day/emojis/master/emojis.csv
# input your custom path to file
# --
# I updated the file with native utf-8 emojis. Since they are stored in a MySQL table it's
# not necessary to use the r.encoded emojis.

emDict_raw <- read.csv2("..../emoji_mod_jh.csv") %>%
  select(EN, ftu8, native, unicode) %>%
  rename(description = EN, r.encoding = ftu8)


# plain skin tones
skin_tones <- c("light skin tone",
                "medium-light skin tone",
                "medium skin tone",
                "medium-dark skin tone",
                "dark skin tone")

# remove plain skin tones and remove skin tone info in description
emDict <- emDict_raw %>%
  # remove plain skin tones emojis
  filter(!description %in% skin_tones) %>%
  # remove emojis with skin tones info, e.g. remove woman: light skin tone and only
  # keep woman
  filter(!grepl(":", description)) %>%
  mutate(description = tolower(description))
#  mutate(unicode = as.u_char(unicode))
# all emojis with more than one unicode codepoint become NA

matchto <- emDict$native
description <- emDict$description
displaynative <- emDict$native

## ---- most used emoji ----
# rank emojis by occurence in data
rank <- emojis_matching(fbcomments$text, matchto, description) %>%
  group_by(description) %>%
  summarise(n = sum(count)) %>%
  arrange(-n)

head(rank, 20)

total <- merge(rank, emDict, by="description")

# Write CSV in R
write.csv(total, file = ".../rank.csv")
