#R4DS 2nd edition teaching script
#this script is based on R for Data Science https://r4ds.hadley.nz/
#suggested answers for book problems can be found here: https://mine-cetinkaya-rundel.github.io/r4ds-solutions

#Hands-On Programming with R is also a good resource: https://rstudio-education.github.io/hopr/

####Setup Block####
##the first block of code in any R script should (minimally) be a setup block that:
#installs packages
#loads libraries
#sets your working directory

#we will use this script for several sessions.  It is important that the first thing you do is to run the setup block.

#package installs
#this syntax checks if a package is installed, installs it if not.

if (!require('tidyverse')) install.packages('tidyverse')
if (!require('palmerpenguins')) install.packages('palmerpenguins')
if (!require('nycflights13')) install.packages('nycflights13')
if (!require('rstudioapi')) install.packages('rstudioapi')
if (!require('readxl')) install.packages('readxl')
if (!require('ggthemes')) install.packages('ggthemes')

#library loadings
library(tidyverse)
library(palmerpenguins)
library(rstudioapi)
library(nycflights13)
library(readxl)
library(ggthemes)

#setting a working directory
#following command assumes you have rstudioapi installed/loaded and sets working directory to script directory
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
getwd()

####Basics####

#The four panes: Script/Environment/File/Console
#Relationship between script and console panes
#enter 1+1 in console pane below
#next, run the next line
1+1

#line numbers
100:130

##combine, vectors, and lists
#This is a vector
c(100:130)
#This is a forced character vector
c(100:130, letters)
#This is a list
list(100:130, letters)

#incomplete commands
5 - 
  
#objects
1:6
a <- 1:6
a

#functions and arguments
round(3.1415) # single argument
?round
round(3.1415, digits = 2) #two arguments, separated by comma

#snake case
#i_use_snake_case

#camel case
#iUseCamelCase

#Why do we use snakes and camels?
pi rounded <- round(3.1415, digits = 2)
pi_rounded <- round(3.1415, digits = 2)

####Section 7: Data import####
#note the path here.  your working directory should be scripts, so your data is up one (..), then down one to data
#The (..) convention means "up one directory" and is a relative path
#contrast the relative path "../data/heights.csv" 
#with the absolute path "/usr/dgauthie/documents/Github/2024_R_seminar/data/heights.csv"

heights <- read_csv("../data/heights.csv")

#reading an individual .xlsx sheet with read_excel
#The "import dataset" wizard in the environment pane is a handy cheat for this.

penguins_Torgerson <- read_excel("../data/penguins.xlsx", 
                                 sheet = "Torgersen Island", #note we don't have to use snake case.  Why?
                                 col_types = c("text", "text", "numeric", "numeric", "numeric", 
                                               "numeric", "text", "numeric"))
View(penguins_Torgerson)

#read in the other sheets in penguins.xlsx

penguins_Biscoe <- read_excel("../data/penguins.xlsx", 
                              sheet = "Biscoe Island", 
                              col_types = c("text", "text", "numeric", "numeric", "numeric", 
                                            "numeric", "text", "numeric"))
View(penguins_Biscoe)

penguins_Dream <- read_excel("../data/penguins.xlsx", 
                             sheet = "Dream Island", 
                             col_types = c("text", "text", "numeric", "numeric", "numeric", 
                                           "numeric", "text", "numeric"))
View(penguins_Dream)

####Section 19: Joins####

#data frames for joining
#where do these data sets come from?
airlines
airports
planes 
weather

#checking whether primary keys for each table are good (uniquely identify each record)
#This is the first time you've seen a pipe (|>) in this class
#also functions count() and filter()
#these are all tidyverse functions, which we'll get to next week in more detail

planes |> 
  count(tailnum) |> 
  filter(n > 1)

#compare with the unpiped version:

df <- count(planes, tailnum)
  filter(df, n > 1)

weather |> 
  count(time_hour, origin) |> 
  filter(n > 1)

#also should examine your keys for missing values 
planes |> 
  filter(is.na(tailnum))

weather |> 
  filter(is.na(time_hour) | is.na(origin))

#mutating joins
#introducing select() here

flights2 <- flights |> 
  select(year, time_hour, origin, dest, tailnum, carrier)
flights2

#left join is the most commonly used form of mutating join.  It is often used to add metadata to a data frame
#what is the key here?

flights2 |>
  left_join(airlines)

flights2 |> 
  left_join(weather |> select(origin, time_hour, temp, wind_speed))

#issues with joining: columns mean different things in the joined tables

flights2 |> 
  left_join(planes)

#solution is to re-specify a key that means the same thing in both tables to be joined

flights2 |> 
  left_join(planes, join_by(tailnum))

#can also join based on keys with different names, provided the same values are present 

flights2 |> 
  left_join(airports, join_by(dest == faa))

#Let's join our three penguins data frames

#this isn't what we want
penguins2 <- left_join(penguins_Biscoe, penguins_Torgerson) |>
  left_join(penguins_Dream)
View(penguins2)

#use rbind instead
penguins3 <- rbind(penguins_Biscoe, penguins_Dream, penguins_Torgerson)
View(penguins3)

#look at NAs in dataframe
penguins3 |>
  filter(if_any(everything(), is.na))

#careful.  There are also "NA" strings in dataframe
penguins3 |>
  filter(if_any(everything(), ~stringr::str_detect(., "NA")))

#let's convert those "NA" strings
penguins4 <- penguins3 |>
  mutate(across(where(is.character), ~na_if(., "NA")))

#Check to see if it worked
penguins4 |>
  filter(if_any(everything(), ~stringr::str_detect(., "NA")))

#This can also be done at the data import step like so: 
penguins_Torgerson <- read_excel("../data/penguins.xlsx", 
                                 sheet = "Torgersen Island", #note we don't have to use snake case.  Why?
                                 col_types = c("text", "text", "numeric", "numeric", "numeric", 
                                               "numeric", "text", "numeric"),
                                 na = "NA") #this has been added
View(penguins_Torgerson)
####


####Section 1: Data Visualization with ggplot2####

#different ways to visualize data set
penguins
glimpse(penguins)
View(penguins)
?penguins

##creating a ggplot (see 1.2.2)
#for folks working on the HPC, you will need to select the cairo backend at "Tools" > "Global Options" > "General" > "Graphics" > "Backend"

#empty graph
ggplot(data = penguins)

#map variables to x and y axes
ggplot(
  data = penguins,
  mapping = aes(x = flipper_length_mm, y = body_mass_g)
)

#add data to the plot with geoms
ggplot(
  data = penguins,
  mapping = aes(x = flipper_length_mm, y = body_mass_g)
) +
  geom_point()

#map species to color aesthetic 
ggplot(
  data = penguins,
  mapping = aes(x = flipper_length_mm, y = body_mass_g, color = species)
) +
  geom_point()

#adding a layer (smoothed line)
ggplot(
  data = penguins,
  mapping = aes(x = flipper_length_mm, y = body_mass_g, color = species)
) +
  geom_point() + 
  geom_smooth(method="lm")

#apply the smoothed line to the entire data set, not to individual species
ggplot(
  data = penguins,
  mapping = aes(x = flipper_length_mm, y = body_mass_g)
) +
  geom_point(mapping = aes(color = species)) +
  geom_smooth(method = "lm")

#map species to both color and shape aesthetics
ggplot(
  data = penguins,
  mapping = aes(x = flipper_length_mm, y = body_mass_g)
) +
  geom_point(mapping = aes(color = species, shape = species)) +
  geom_smooth(method = "lm")

#Improve labeling of plot
ggplot(
  data = penguins,
  mapping = aes(x = flipper_length_mm, y = body_mass_g)
) +
  geom_point(aes(color = species, shape = species)) +
  geom_smooth(method = "lm") +
  labs(
    title = "Body mass and flipper length",
    subtitle = "Dimensions for Adelie, Chinstrap, and Gentoo Penguins",
    x = "Flipper length (mm)", y = "Body mass (g)",
    color = "Species", shape = "Species"
  ) +
  scale_color_colorblind()

##Section 1.3

ggplot(
  data = penguins,
  mapping = aes(x = flipper_length_mm, y = body_mass_g)
) +
  geom_point()

#more concise specification

ggplot(penguins, aes(x = flipper_length_mm, y = body_mass_g)) + 
  geom_point()

#with a "pipe"

penguins |> 
  ggplot(aes(x = flipper_length_mm, y = body_mass_g)) + 
  geom_point()

##Section 1.4

#categorical variable and a new geom
ggplot(penguins, aes(x = species)) +
  geom_bar()

#reordered factors
ggplot(penguins, aes(x = fct_infreq(species))) +
  geom_bar()

#numerical variable and geom_histogram
ggplot(penguins, aes(x = body_mass_g)) +
  geom_histogram(binwidth = 200)

ggplot(penguins, aes(x = body_mass_g)) +
  geom_histogram(binwidth = 20)

ggplot(penguins, aes(x = body_mass_g)) +
  geom_histogram(binwidth = 2000)

#geom_density
ggplot(penguins, aes(x = body_mass_g)) +
  geom_density() 

#1.4.3 exercises

# 1) Make a bar plot of species of penguins, where you assign species to the y aesthetic. How is this plot different?
#   
# 2) How are the following two plots different? Which aesthetic, color or fill, is more useful for changing the color of bars?
#   
#     ggplot(penguins, aes(x = species)) +
#       geom_bar(color = "red")
# 
#     ggplot(penguins, aes(x = species)) +
#       geom_bar(fill = "red")
# 
# 3) What does the bins argument in geom_histogram() do?
#   
# 4) Make a histogram of the carat variable in the diamonds dataset that is available when you load the tidyverse package. 
#     Experiment with different binwidths. What binwidth reveals the most interesting patterns?
# 



##Section 1.5

#Relationship between numerical and categorical variable with different geoms
ggplot(penguins, aes(x = species, y = body_mass_g)) +
  geom_boxplot()

ggplot(penguins, aes(x = species, y = body_mass_g)) +
  geom_point()

ggplot(penguins, aes(x = body_mass_g, color = species)) +
  geom_density(linewidth = 0.75)

#mapping variable species to both color and fill aesthetics
#setting fill aesthetic to a value (0.5)
ggplot(penguins, aes(x = body_mass_g, color = species, fill = species)) +
  geom_density(alpha = .5)

#stacked barplot
ggplot(penguins, aes(x = island)) +
  geom_bar()

ggplot(penguins, aes(x = island, fill = species)) +
  geom_bar()

#using position argument to change behavior of stacked barplot
ggplot(penguins, aes(x = island, fill = species)) +
  geom_bar(position = "dodge")

#getting complicated.  Three or more variables
#basic plot
ggplot(penguins, aes(x = flipper_length_mm, y = body_mass_g)) +
  geom_point()
#adding mappings for species and island
ggplot(penguins, aes(x = flipper_length_mm, y = body_mass_g)) +
  geom_point(aes(color = species, shape = island))
#cleaner way to do this with faceting
ggplot(penguins, aes(x = flipper_length_mm, y = body_mass_g)) +
  geom_point(aes(color = species, shape = species)) +
  facet_grid(species ~ island)


##Challenge for 10/2##
#Use the `diamonds` dataframe from the ggplot2 package.  
#I want to buy a diamond (I really don't).  
#Create a script (new file) that will do the following:
#Make some plots that will give me an idea of what my best value is in terms of color and cut.
#By value, if I can expect on average to buy a better cut (or color) for the same price/carat as a lesser cut (or color), that is what I am going to shop for.
#No stats.  Make some plots.
#GO
View(diamonds)

diamonds |>
  ggplot(aes(x=carat, y=price, color = cut)) +
  geom_point() +
  geom_smooth(method = "lm") +
  facet_grid(cut~color)

df <- diamonds |>
  mutate(pricepercarat = price/carat) |>
  ggplot(aes(x=color, y=pricepercarat)) +
  geom_boxplot() +
  facet_grid(~cut)


####Section 3: Data Transformation####

flights
?flights

#The first tidyverse row function: filter

#filter operates on ROWS
flights <- flights |> 
  filter(dep_delay > 120)

# Flights that departed on January 1
flights |> 
  filter(month == 1 & month == 1)

# Flights that departed in January or February
df <- flights |> 
  filter(month == 1 | month == 2)

# multiple operations in a pipe
flights |> 
  filter(dep_delay > 120) |>
  filter(month == 1 & day == 1)

# A shorter way to select flights that departed in January or February
flights |> 
  filter(month %in% c(1:10))

#saving to an object
jan1 <- flights |> 
  filter(month == 1 & day == 1)

##Section 3.2.2: Common Mistakes

flights |> 
  filter(month = 1)

flights |> 
  filter(month == 1 | 2)

#3.2.3 our next row function: arrange
#changes order of rows based on column values

var <- flights |> 
  arrange(month, dep_delay)

flights |> 
  arrange(desc(dep_delay))

#3.2.4 distinct

# Remove duplicate rows, if any
flights |> 
  distinct()

# Find all unique origin and destination pairs
flights |> 
  distinct(origin, dest)

flights |>
  filter(origin == "EWR" & dest == "IAH")

#as above, keeping all columns
flights |> 
  distinct(origin, dest, .keep_all = TRUE)

#Section 3.3: Column functions

#mutate (you'll probably use this one more than any other)
new_flights <- flights |> 
  mutate(
    gain = dep_delay - arr_delay, 
    speed = distance / air_time * 60, 
    .after = day
    )

View(new_flights)

flights |> 
  mutate(
    gain = dep_delay - arr_delay,
    speed = distance / air_time * 60,
    .before = 1
  )

flights |> 
  mutate(
    gain = dep_delay - arr_delay,
    speed = distance / air_time * 60,
    .after = day
  )

flights |> 
  mutate(
    gain = dep_delay - arr_delay,
    hours = air_time / 60,
    gain_per_hour = gain / hours,
    .keep = "used"
  )

#select: filters by column instead of row
flights |> 
  select(year, month, day)

flights |> 
  select(year:flight)

flights |> 
  select(!year:day)

flights |> 
  select(where(is.numeric))

#one way to rename a column
#note syntax is select(new_name = old_name)
new_flights <- flights |> 
  select(dep_time, everything())

#rename can also be used for this
new_flights <- flights |> 
  rename(tail_num = tailnum)

#relocate
flights |> 
  relocate(time_hour, air_time)

flights |> 
  relocate(year:dep_time, .after = time_hour)

flights |> 
  relocate(starts_with("arr"), .before = dep_time)

##Section 3.5: group_by() and summarize()

flights |> 
  group_by(month)

flights |> 
  group_by(month) |> 
  summarize(
    avg_delay = mean(dep_delay)
  )

flights |> 
  group_by(month) |> 
  summarize(
    avg_delay = mean(dep_delay, na.rm = TRUE)
  )

flights |> 
  group_by(month) |> 
  summarize(
    avg_delay = mean(dep_delay, na.rm = TRUE), 
    n = n(),
    sd_delay = sd(dep_delay, na.rm = TRUE),
    max_delay = max(dep_delay, na.rm = TRUE),
    min_delay = min(dep_delay, na.rm = TRUE)
  )

#grouping by multiple variables

daily <- flights |>  
  group_by(year, month, day)
daily

daily_flights <- daily |> 
  summarize(n = n())
daily_flights

daily |> 
  filter(!if_any(everything(), is.na)) |>
  summarize(n = n())


####Section 5: Data tidying and pivoting####

#table 1 is tidy
table1
table1 |>
  mutate(rate = cases / population * 10000)

table1 |> 
  group_by(country) |> 
  summarize(total_cases = sum(cases))

ggplot(table1, aes(x = year, y = cases)) +
  geom_line(aes(group = country), color = "grey50") +
  geom_point(aes(color = country, shape = country)) +
  scale_x_continuous(breaks = c(1999, 2000)) 

#table 2 has variables as values

table2

#what's untidy about table 3?

table3 

#lengthening data 

df <- tribble(
  ~id,  ~bp1, ~bp2,
  "A",  100,  120,
  "B",  140,  115,
  "C",  120,  125
)

df |> 
  pivot_longer(
    cols = bp1:bp2,
    names_to = "measurement",
    values_to = "value"
  )

#making data wider

df <- tribble(
  ~id, ~measurement, ~value,
  "A",        "bp1",    100,
  "B",        "bp1",    140,
  "B",        "bp2",    115, 
  "A",        "bp2",    120,
  "A",        "bp3",    105
)

df |> 
  pivot_wider(
    names_from = measurement,
    values_from = value
  )

####Section 15: Regular Expressions####

#literal matches
str_view(fruit, "berry")

#any character (.)
str_view(fruit, "a...e")

#quantifiers (?, +, *)
str_view(c("a", "ab", "abb"), "ab?")

str_view(c("a", "ab", "abb"), "ab+")

str_view(c("a", "ab", "abb"), "ab*")

#character classes ([])

str_view(words, "[aeiou]x[aeiou]")

#negated character class ([^])

str_view(words, "[^aeiou]y[^aeiou]")

#alternation (|)
str_view(fruit, "apple|melon|nut")
str_view(fruit, "aa|ee|ii|oo|uu")

str_view(fruit, "o{2}")
####
