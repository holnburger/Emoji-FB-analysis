# Emoji-FB-analysis

Analysis of Emoji usage in Facebook comments. You need the comments stored on an SQL-server. I downloaded all posts and comments via DMI netvizz, you can also write your own FB crawler.

Credits to Jessica Peterka-Bonetta who has written most of the script, i only optimized it to use multiple cores (via Parallel) and get comments from my SQL server. https://github.com/today-is-a-good-day/emojis/blob/master/emoji_analysis.R

## Requirements
MySQL-Server
R-Packages:
* parallel
* RMySQL
* stringr
* base64enc
* tm
* Unicode
* rvest
* dplyr
