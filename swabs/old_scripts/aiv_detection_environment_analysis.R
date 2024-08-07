# Script: aiv_detection_environment_analysis.R
# This file is an R script that couples sequencing information with sample information to arive at the main conclusions in the manuscript
# NOTE: This file depends on minion_demultiplexing_flu_assignment.sh. Run that script first!

#This script is part of the following manuscript:
#Analysis of MinION sequence data from water and sediment samples for avian influenza detection in California wetlands
#This github repository includes code (and links to data) from the manuscript:
#"Linking remote sensing for targeted surveillance of Avian Influenza virus via tangential flow ultra-filtration and whole segment amplification in California wetlands"
#Madeline M. McCuen | Maurice E. Pitesky | Ana Paula da Silva | Rodrigo A. Gallardo | Jeff J. Buler | Sarai Acosta | Alexander Wilcox | Ronald F. Bond | Samuel L. Díaz-Muñoz

################ Avian Influenza Viruses Environment ################
#### 1. Data Sources and Preparing Data
#### 2. Analysis of Collected Samples
#### 3. Analysis of Sequencing Reads and FluDB Database Metadata 

#THIS CODE NEEDS FOLOWING FILES: 
# AIV_filtration sample key 9_26_18.xls, 
# data/Temp_pH_Salinitt_for_B&C.csv,
# demultiplexing_by_sample.txt - This file generated by script minion_demultiplexing_flu_assignment.sh 
# avian_blast_matches.txt - This file generated by script minion_demultiplexing_flu_assignment.sh
# Individual sample *.out and *.tab files generated by script minion_demultiplexing_flu_assignment.sh 

#Project Description
#Analysis of MinION sequence data from water and sediment samples for avian influenza detection in California wetlands
#Code for "Linking remote sensing for targeted surveillance of Avian Influenza virus via tangential flow ultra-filtration and whole segment amplification in California wetlands"
#Collaboration between Diaz-Munoz Lab and Madeline McCuen, Maurice Pitesky (PI), UC Davis

#Load libraries
library(readr)
library(tidyr)
library(ggplot2)
library(dplyr)
library(ggthemes)
library(gridExtra)
library(reshape2)

#### 1. Data Sources and Preparing Data   ####

#Received a spreadsheet from Madeline McCuen via email on September 28, 2018 at 4:59pm
# entitled "AIV_filtration sample key 9_26_18.xlsx" Saved this file as CSV from Excel to import to R

#Import data from CSV, requires readr package
AIV_filtration_sample_key_9_26_18 <- read_csv("data/AIV_filtration_sample_key_9_26_18.csv")

#View
#View(AIV_filtration_sample_key_9_26_18)
#OK, can see that there were some extra columns that were merged in original spreadsheet

#Remove irrelevant columns, including key, which I already copied
aiv_filtration <- AIV_filtration_sample_key_9_26_18[1:44,c("Sample Number","Sample Label")]

#Adding samples that I used as PCR controls
aiv_filtration$`Sample Number`[42:44] <- c(42, 43, 44)
aiv_filtration$`Sample Label`[42:44] <- c("PR8 RNA A", "PR8 RNA B", "PCR NEG")

#Now filling in data from gel manually, by consulting gels
#aiv_water_sediment_usdagrant_half1_2018-0926-111315.tif (samples 1-24, sequentially L-R in wells)
#aiv_water_sediment_usdagrant_half2_2018-0926-111717.tif (samples 25-44, sequentially L-R in wells)
bands <- c(8, 0, 5, 7, 0, 1, 0, 1, 0, 0, 5, 1, 
           4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 4,
           1, 4, 1, 1, 4, 2, 2, 0, 1, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 2, 0)

#Now bind this bands results vector to our AIV data frame
#Test/Check
#View(cbind(aiv_filtration, bands))
#Implement
aiv_filtration <- cbind(aiv_filtration, bands)
head(aiv_filtration)

#Now parse out the data in the sample label. Fill in semi-automated way
#Fill in vector for filtration, this will be new column in aiv_filtration data frame
filtration <- NULL
filtration[grep("RXD", aiv_filtration$`Sample Label`)] <- "RXD"
filtration[grep("GE", aiv_filtration$`Sample Label`)] <- "GE"
filtration[grep("Unfltrd", aiv_filtration$`Sample Label`)] <- "Unfltrd"
filtration[34:44] <- rep(NA, 11)

#Now fill in vector for collection location, this will be new column in aiv_filtration data frame
location <- NULL
location[grep("^A", aiv_filtration$`Sample Label`)] <- "A. Butte county wetland"
location[grep("^B", aiv_filtration$`Sample Label`)] <- "B. Yolo bypass wildlife area"
location[grep("^C", aiv_filtration$`Sample Label`)] <- "C. Yolo bypass wildlife area"
length(location)
#38
location[38:44] <- rep(NA, 7)

#Now bind columns filtration and location to the aiv_filtration data frame
aiv_filtration <- cbind(aiv_filtration, filtration, location)

#Perhaps looking at gel bands would be better with yes/no bands answer
# If there's band, then indicate Yes, if no No
band_present <- ifelse(aiv_filtration$bands > 0, "Yes", "No")
#Bind to data frame
aiv_filtration <- cbind(aiv_filtration, band_present)
head(aiv_filtration)

#Now adding the number of reads recovered from demultiplexed files. Will add separate columns for number of reads that matched avian influenza genomes
demultiplexing_by_sample <- read.table("demultiplexing_by_sample.txt", quote="\"", comment.char="", col.names = c("reads", "sample"))

#Partition forward and reverse reads
demultiplexing_by_sample <- separate(demultiplexing_by_sample, sample, c("direction", "sample"), sep = "^*_", extra = "merge")

#Make separate columns for reverse and forward reads 
demultiplexing_by_sample <- dcast(demultiplexing_by_sample, sample~direction, value.var = "reads")

colnames(demultiplexing_by_sample) <- c("Sample Label", "forward_reads", "reverse_reads")
#colnames(avian_blast_matches) <- c("Sample Label", "forward_avian", "reverse_avian")

#Clean up samples to make sample label match aiv_filtration
demultiplexing_by_sample$`Sample Label` <- gsub(".fast.", "", demultiplexing_by_sample$`Sample Label`)
demultiplexing_by_sample$`Sample Label` <- gsub("_", " ", demultiplexing_by_sample$`Sample Label`)

#Remove NA's and replace by zeros
demultiplexing_by_sample[is.na(demultiplexing_by_sample)] <- 0

#Let's add a total column for all the reads assigned to that particular sample
demultiplexing_by_sample <- mutate(demultiplexing_by_sample, reads_assigned=forward_reads+reverse_reads)

#Let's add to aiv_filtration
aiv_filtration <- left_join(aiv_filtration, demultiplexing_by_sample)
#Removing NA's: carefully!!
aiv_filtration$forward_reads[is.na(aiv_filtration$forward_reads)] <- 0
aiv_filtration$reverse_reads[is.na(aiv_filtration$reverse_reads)] <- 0
aiv_filtration$reads_assigned[is.na(aiv_filtration$reads_assigned)] <- 0

#Now adding separate columns for number of reads that matched avian influenza genomes
avian_blast_matches <- read.table("avian_blast_matches.txt", quote="\"", comment.char="", col.names = c("avian", "sample"))

#Partition forward and reverse reads
avian_blast_matches <- separate(avian_blast_matches, sample, c("direction", "sample"), sep = "^*_", extra = "merge")

#Make separate columns for reverse and forward reads 
avian_blast_matches <- dcast(avian_blast_matches, sample~direction, value.var = "avian")

#Rename columns
colnames(avian_blast_matches) <- c("Sample Label", "forward_avian", "reverse_avian")

#Clean up samples to make sample label match aiv_filtration
avian_blast_matches$`Sample Label` <- gsub(".out", "", avian_blast_matches$`Sample Label`)
avian_blast_matches$`Sample Label` <- gsub("_", " ", avian_blast_matches$`Sample Label`)

#Remove NA's and replace by zeros
avian_blast_matches[is.na(avian_blast_matches)] <- 0

#Let's add a total column for all the reads assigned to that particular sample
avian_blast_matches <- mutate(avian_blast_matches, avian_read_matches=forward_avian+reverse_avian)

#Let's add to aiv_filtration
aiv_filtration <- left_join(aiv_filtration, avian_blast_matches)
#Removing NA's: carefully!!
aiv_filtration$forward_avian[is.na(aiv_filtration$forward_avian)] <- 0
aiv_filtration$reverse_avian[is.na(aiv_filtration$reverse_avian)] <- 0
aiv_filtration$avian_read_matches[is.na(aiv_filtration$avian_read_matches)] <- 0

#Getting the sample location so I can pair filtered and unfiltered
aiv_filtration <- separate(aiv_filtration, 'Sample Label', "Sample", sep = " ", remove = F)
#Warning ok

#Add data on salinity, pH, and temp to main dataframe (aiv_filtration) 
temp_ph_salinity <- read_csv("data/Temp_pH_Salinitt_for_B&C.csv")
#View(temp_ph_salinity)
colnames(temp_ph_salinity) <- c("Sample", "temp", "salinity", "pH")
#View(aiv_filtration)
#View(left_join(aiv_filtration, temp_ph_salinity))
aiv_filtration <- left_join(aiv_filtration, temp_ph_salinity)

#### 2. Analysis of Collected Samples ####

#First, let's look at Filtration Method vs Reads Matching AIV 
#Removing NA's for filtration which would exclude controls and sedmiment samples
figure5 <- ggplot(subset(aiv_filtration, filtration != "NA"), aes(x = filtration, y = avian_read_matches, color=location)) + 
  geom_point(position=position_jitter(width = .2, height = .05), size=3.5, alpha=0.75)
figure5
ggsave("figure5.pdf", figure5)
#We can see we have a huge outlier

#Let's plot without outlier B1 SW Unfltrd
ggplot(subset(aiv_filtration, filtration != "NA" & `Sample Label` != "B1 SW Unfltrd"), aes(x = filtration, y = avian_read_matches, color=location)) + 
  geom_point(position=position_jitter(width = .2, height = .05), size=3.5, alpha=0.75)
#Let's make this plot a boxplot (see gf1 below) and include along with another boxplot broken down by sampling site 

#Boxplot overall for filtration w/o outlier
gf1 <- ggplot(subset(aiv_filtration, filtration != "NA" & `Sample Label` != "B1 SW Unfltrd"), aes(x = filtration, y = avian_read_matches)) + geom_point(position=position_jitter(width = .1, height = .05)) + geom_boxplot(alpha=0.4)
gf1

#Boxplot broken down by site using facets
gf <- ggplot(subset(aiv_filtration, filtration != "NA" & `Sample Label` != "B1 SW Unfltrd"), aes(x = filtration, y = avian_read_matches)) + geom_point(position=position_jitter(width = .1, height = .05)) + geom_boxplot(alpha=0.4) + facet_wrap(~ location)
gf

#Bring boxplots together to make Figure 6 in the text
figure6 <- grid.arrange(gf, gf1)
figure6
ggsave("figure6.pdf", figure6)

#Now we have some summary statistics. These are referenced in the text under Results: "Recovery of Avian Influenza Sequences from Water Samples With and Without Filtration"
#Note that in text we present summary statistics with the outlier, but excluding samples that had value == 0

#Let's use dplyr to get summary stats
group_by(subset(aiv_filtration, filtration != "NA"), filtration) %>%
  summarise(
    count = n(),
    mean = mean(avian_read_matches, na.rm = TRUE),
    sd = sd(avian_read_matches, na.rm = TRUE)
  )
# A tibble: 3 x 4
#filtration count   mean      sd
#<fct>      <int>  <dbl>   <dbl>
#  1 GE           3  0.333   0.577
#2 RXD           15 12.6    30.3  
#3 Unfltrd       15 51.9   191.

#RXD better than GE, but unfiltered better. Is this due to outlier?

#Now same, but without the outlier
group_by(subset(aiv_filtration, filtration != "NA" & `Sample Label` != "B1 SW Unfltrd"), filtration) %>%
  summarise(
    count = n(),
    mean = mean(avian_read_matches, na.rm = TRUE),
    sd = sd(avian_read_matches, na.rm = TRUE)
  )
# A tibble: 3 x 4
#filtration count   mean     sd
#<fct>      <int>  <dbl>  <dbl>
#  1 GE           3  0.333  0.577
#2 RXD           15 12.6   30.3  
#3 Unfltrd       14  2.64   3.95

#Yep! Driven by outlier. 

#Let's do with dplyr to get summary stats, but now excluding zeros
group_by(subset(aiv_filtration, filtration != "NA" & avian_read_matches > 0), filtration) %>%
  summarise(
    count = n(),
    mean = mean(avian_read_matches, na.rm = TRUE),
    sd = sd(avian_read_matches, na.rm = TRUE)
  )
# A tibble: 3 x 4
#filtration count  mean    sd
#<fct>      <int> <dbl> <dbl>
#1 GE             1   1    NA  
#2 RXD            8  23.6  39.2
#3 Unfltrd       10  77.8 233. 

#Now same, but without the outlier and non zeros
group_by(subset(aiv_filtration, filtration != "NA" & `Sample Label` != "B1 SW Unfltrd" & avian_read_matches > 0), filtration) %>%
  summarise(
    count = n(),
    mean = mean(avian_read_matches, na.rm = TRUE),
    sd = sd(avian_read_matches, na.rm = TRUE)
  )
# A tibble: 3 x 4
#filtration count  mean    sd
#<fct>      <int> <dbl> <dbl>
#1 GE             1  1    NA   
#2 RXD            8 23.6  39.2 
#3 Unfltrd        9  4.11  4.31

#Now we do a formal stats test, to see if there is any difference in filtration method (excluding GE as too few reads). 
#We conducted the t-tests excluding samples == 0 and excluding the outlier. Overall result stays the same if t-test includes these samples

#Subsetting for RXD and Unfiltered
#Not including zero data points and exclusing outlier
rxd <- subset(aiv_filtration, filtration == "RXD" & filtration != "NA" & avian_read_matches > 0, select = avian_read_matches, drop = T)
unfltrd <- subset(aiv_filtration, filtration == "Unfltrd" & filtration != "NA"  & avian_read_matches > 0  & `Sample Label` != "B1 SW Unfltrd", select = avian_read_matches, drop = T)

t.test(rxd, unfltrd)
#Welch Two Sample t-test 
#data:  rxd and unfltrd
#t = 1.4013, df = 7.151, p-value = 0.203
#alternative hypothesis: true difference in means is not equal to 0
#95 percent confidence interval:
#  -13.27455  52.30232
#sample estimates:
#  mean of x mean of y 
#23.625000  4.111111 

#As seen above the mean number of reads is not statistically significanty different, however are the number of positives *samples* different?
#So first looking at a total of 15 unfiltered (including outlier) of which 10 were positive (see below)
length(subset(aiv_filtration, filtration == "Unfltrd" & filtration != "NA", select = avian_read_matches, drop = T))
#[1] 15
length(subset(aiv_filtration, filtration == "Unfltrd" & filtration != "NA" & avian_read_matches > 0, select = avian_read_matches, drop = T))
#[1] 10
#Then looking at a total of 15 Rexeed filtered samples
length(subset(aiv_filtration, filtration == "RXD" & filtration != "NA", select = avian_read_matches, drop = T))
#[1] 15
length(subset(aiv_filtration, filtration == "RXD" & filtration != "NA" & avian_read_matches > 0, select = avian_read_matches, drop = T))
#[1] 8

#Now we conduct proportion test with numbers above 
prop.test(c(8, 10), c(15, 15), correct=T)
#2-sample test for equality of proportions with continuity correction
#data:  c(8, 10) out of c(15, 15)
#X-squared = 0.13889, df = 1, p-value = 0.7094
#alternative hypothesis: two.sided
#95 percent confidence interval:
#  -0.5473475  0.2806808
#sample estimates:
#  prop 1    prop 2 
#0.5333333 0.6666667 
#Hypothesis that the proportion of positive samples is different, is rejected


#Next we analyzed the number of positive samples (i.e. those with reads matching AIV) overall
#These results reported in Results: Whole-segment amplification/sequencing yielded more positive samples than M-segment RT-qPCR

#Include only samples, not controls, nor sediment samples   
nrow(aiv_filtration[1:33, ])
#[1] 33
#This is total number of samples

#We count as positive the samples that had at least one read matching avian influenza virus genomes database
table(aiv_filtration[1:33, ]$avian_read_matches > 0)
#FALSE  TRUE 
#14    19 

#Comparing proportion of positive samples with qPCR (1/38) with M-RTPCR/sequencing (19/38) 
#prop.test(c(1, 19), c(33, 33), correct=T)
#2-sample test for equality of proportions with continuity correction

#data:  c(1, 19) out of c(33, 33)
#X-squared = 20.733, df = 1, p-value = 5.281e-06
#alternative hypothesis: two.sided
#95 percent confidence interval:
#  -0.7542358 -0.3366733
#sample estimates:
#  prop 1     prop 2 
#0.03030303 0.57575758
#Thus, number of positive samples was different using RT-qPCR vs amplification/sequencing

#Possible question regarding the difference in detection between the two samples: is it due to amplification or sequencing  
#Mostly amplification as seen below:

#Straightforward way to answer question is to ask: If I had a band on gel, did I see reads? (YES)
#If i didn't see a band, did I get reads (NO) 
#Comparison of band presence and number of avian reads obtained 
figure_S2 <- ggplot(subset(aiv_filtration, filtration != "NA"), aes(x = band_present, y = avian_read_matches)) + 
  geom_point(position=position_jitter(width = .1), size=3.5, alpha=0.75) + geom_boxplot(alpha=0.4) 
figure_S2
ggsave("figure_S2.pdf", figure_S2)
#If there's a band we get more sequences! Does not include outlier, which did have bands, for ease of visualization

## BONUS SECTION: These figures are not included in manuscript and are presented here in the code only
  #Only for people that like to read deep into code ;) 

#By location without filtration
ggplot(subset(aiv_filtration, filtration != "NA" & `Sample Label` != "B1 SW Unfltrd" & avian_read_matches != 0), aes(x = location, y = avian_read_matches, color=filtration)) + 
  geom_point(position=position_jitter(width = .2), size=3.5, alpha=0.75) 

#Same with boxplot
ggplot(subset(aiv_filtration, filtration != "NA" & `Sample Label` != "B1 SW Unfltrd"), aes(x = location, y = avian_read_matches)) + 
  geom_point(position=position_jitter(width = .2, height = .05), size=3.5, alpha=0.75) + geom_boxplot(alpha=0.4)

#Quick look at Temperature
ggplot(aiv_filtration, aes(x = temp, y = avian_read_matches, color=location)) + geom_point()

#Quick look at salinity
ggplot(aiv_filtration, aes(x = salinity, y = avian_read_matches, color=location)) + geom_point()

#Quick look at pH
ggplot(aiv_filtration, aes(x = pH, y = avian_read_matches, color=location)) + geom_point()

#Outlier seems to be clouding things. Try removing. Actually looks like controls are pushing axis to 6000
temp_reads <- ggplot(subset(aiv_filtration, temp != "NA"), aes(x = temp, y = avian_read_matches, color=location)) + geom_point()
temp_reads

#Add thresholds that suggest environmental factors under which AIV can remain viable from Stallknecht et al 1990
temp_reads_thresh <- temp_reads + geom_vline(xintercept = c(17, 28), linetype="dotted", color = "black", alpha = 0.5 , size=1.5)
temp_reads_thresh

salinity_reads <- ggplot(subset(aiv_filtration, temp != "NA"), aes(x = salinity, y = avian_read_matches, color=location)) + geom_point()
salinity_reads

pH_reads <- ggplot(subset(aiv_filtration, temp != "NA"), aes(x = pH, y = avian_read_matches, color=location)) + geom_point()
pH_reads

#Any linear pattern of reads with environmental factors? Nope!
temp_reads_linear <- ggplot(subset(aiv_filtration, temp != "NA"), aes(x = temp, y = avian_read_matches)) + geom_point() + geom_smooth(method=lm, se=T)
temp_reads_linear

salinity_reads_linear <-ggplot(subset(aiv_filtration, temp != "NA"), aes(x = salinity, y = avian_read_matches)) + geom_point() + geom_smooth(method=lm, se=T)
salinity_reads_linear

pH_reads_linear <- ggplot(subset(aiv_filtration, temp != "NA"), aes(x = pH, y = avian_read_matches)) + geom_point() + geom_smooth(method=lm, se=T)
pH_reads_linear

summary(lm(avian_read_matches ~ temp, aiv_filtration))
summary(lm(avian_read_matches ~ pH, aiv_filtration))
summary(lm(avian_read_matches ~ salinity, aiv_filtration))

## END BONUS SECTION

#### 3. Analysis of Sequencing Reads and FluDB Database Metadata #### 

##First we need import and clean up data. 
#We'll start with importing information from .tab files, which contain metadata for the sequences in FluDB
file_names <- list.files(".", "*.tab")

metadata_avian <- NULL

for (i in 1:length(file_names)) {
  #import each file and add recursively to a data frame
  results <- read_delim(file_names[i], "|", escape_double = FALSE, col_names = FALSE, trim_ws = TRUE)
  
  sample <- rep(file_names[i], nrow(results))
  results <- cbind(results, sample)
  
  metadata_avian <- rbind(metadata_avian, results)
}  

colnames(metadata_avian) <- c("gi", "organism", "strain", "segment", "subtype", "host", "Sample Label")
#Cleanup Data Frame Contents
metadata_avian$gi <- gsub(">*[A-z]*:", "", metadata_avian$gi)
metadata_avian$strain <- gsub("[A-z]*\\s[A-z]*:", "", metadata_avian$strain)
metadata_avian$organism <- gsub("[A-z]*:", "", metadata_avian$organism)
metadata_avian$segment <- gsub("[A-z]*:", "", metadata_avian$segment)
metadata_avian$subtype <- gsub("[A-z]*:", "", metadata_avian$subtype)
metadata_avian$host <- gsub("[A-z]*:", "", metadata_avian$host)

metadata_avian$'Sample Label' <- gsub("sample_*", "", metadata_avian$'Sample Label')
metadata_avian$'Sample Label' <- gsub("*.tmp.tab", "", metadata_avian$'Sample Label')
metadata_avian$'Sample Label' <- gsub("_", " ", metadata_avian$'Sample Label')
metadata_avian$'Sample Label' <- gsub("reverse ", "", metadata_avian$'Sample Label')
metadata_avian$'Sample Label' <- gsub("forward ", "", metadata_avian$'Sample Label')

#View(metadata_avian)
#View(right_join(metadata_avian, aiv_filtration))

metadata_avian <- right_join(metadata_avian, aiv_filtration)

#Fix the mixed subtypes category
metadata_avian$subtype <- gsub("Mixed", "mixed", metadata_avian$subtype)

#Make a new data frame excluding positive control samples
metadata_avian_samples <- subset(metadata_avian, `Sample Label` != "PR8 RNA A" & `Sample Label` != "PR8 RNA B")

#Now that we're done with metadata, let's bring in the sequence matching information and pair it with the segment information
file_list <- list.files(".", "*.out")

sequence_match_info <- NULL

for (i in 1:length(file_list)) {
  #import each file and add recursively to a data frame
  results <- read_delim(file_list[i], "\t", escape_double = FALSE, col_names = FALSE, trim_ws = TRUE)
  #colnames(results) <- c("qid", "match", "percent_id", "alignment_length", "mismatches", "gap_opens", "start_query", "end_query", "start_target", "end_target", "evalue", "bitscore")
  
  sample <- rep(file_list[i], nrow(results))
  results <- cbind(results, sample)
  
  sequence_match_info <- rbind(sequence_match_info, results)
}

nrow(sequence_match_info)
#[1] 4782

colnames(sequence_match_info) <- c("qid", "match", "percent_id", "alignment_length", "mismatches", "gap_opens", "start_query", "end_query", "start_target", "end_target", "evalue", "bitscore", "sample")

#Clean up sample name
sequence_match_info$sample <- gsub("forward_", "", sequence_match_info$sample)
sequence_match_info$sample <- gsub("reverse_", "", sequence_match_info$sample)
sequence_match_info$sample <- gsub("*.out", "", sequence_match_info$sample)
sequence_match_info$sample <- gsub("_", " ", sequence_match_info$sample)

#Extract GB to match
sequence_match_info$match <- gsub("gb:", "", sequence_match_info$match)
sequence_match_info$match <- gsub("\\|[A-z]*:[A-z]*", "", sequence_match_info$match)

#Adjust colnames for join
colnames(sequence_match_info) <- c("qid", "gi", "percent_id", "alignment_length", "mismatches", "gap_opens", "start_query", "end_query", "start_target", "end_target", "evalue", "bitscore", "Sample Label")

#How many sequences left if I remove the positive control
nrow(subset(sequence_match_info, `Sample Label` != "PR8 RNA A" & `Sample Label` != "PR8 RNA B"))
#[1] 968

#Remove Positive Controls (test)
#View(subset(sequence_match_info, `Sample Label` != "PR8 RNA A" & `Sample Label` != "PR8 RNA B"))

#Subset to remove positive controls
sequence_match_info_samples <- subset(sequence_match_info, `Sample Label` != "PR8 RNA A" & `Sample Label` != "PR8 RNA B")


##Now we can get down to analyses. #These are reported in manuscripts under Results: "Sequencing Data and AIv Database Match Summary"

#Mean alignment length across all segments
mean(sequence_match_info_samples$alignment_length)
#[1] 1217.427

#Number of segments with alignment length over 2.2kpbs
nrow(subset(sequence_match_info_samples, alignment_length > 2200))
#[1] 80

#Of those, how many are > 2.3kpbs?
nrow(subset(sequence_match_info_samples, alignment_length > 2300))
#[1] 71

#Accuracy?
mean(subset(sequence_match_info_samples, alignment_length > 2300)$percent_id)
#[1] 90.83168

#Mean alignment length
mean(sequence_match_info_samples$alignment_length)
#1217.427
sd(sequence_match_info_samples$alignment_length)
#506.6612
length(sequence_match_info_samples$alignment_length)
#[1] 968

#Mean percentage identity
mean(sequence_match_info_samples$percent_id)
#[1] 91.63504
sd(sequence_match_info_samples$percent_id)
#[1] 3.608673
length(sequence_match_info_samples$percent_id)
#[1] 968

#Histogram of PID matches
hist(sequence_match_info_samples$percent_id)

#Now we want to add sequence match metadata, but only to existing records
metadata_avian_distinct <- distinct(metadata_avian, gi, .keep_all = TRUE)

#Get only the info from the IRD database
metadata_avian_distinct <- subset(metadata_avian_distinct, select = c("gi", "organism", "strain", "segment", "subtype", "host"))

#Test Join
#View(inner_join(sequence_match_info_samples, metadata_avian_distinct, by = "gi"))

#Join
sequence_match_info_samples <- inner_join(sequence_match_info_samples, metadata_avian_distinct, by = "gi")

#Test if I affected anything with join
mean(sequence_match_info_samples$alignment_length)
#[1] 1217.427
#Same as above, so looks good

#What is the segment match distribution
#These results are repoted in Table 2 in manuscript and also in text 
table(sequence_match_info_samples$segment)
#  2   3   4   6   7   8 
#87  14  59 395 392  21 

#How many samples have at least 1 M segment match? This is to compare to RT-qPCR results.
table(subset(sequence_match_info_samples, segment == 7, select = `Sample Label`))
#A1 Fltrd RXD A2 SW Unfltrd   A3 Fltrd GE  A3 Fltrd RXD  A4 Fltrd RXD A5 SW Unfltrd B1 SW Unfltrd 
#17             1             1             1             2             2           351 
#B2 SW Unfltrd B3 SW Unfltrd B4 SW Unfltrd  B5 Fltrd RXD B5 SW Unfltrd C3 SW Unfltrd  C5 Fltrd RXD 
#4             5             2             1             1             1             2 
#C5 SW Unfltrd 
#1

nrow(table(subset(sequence_match_info_samples, segment == 7, select = `Sample Label`)))
#[1] 15
#So if I only count M segment matches as positives by sequencing, I would have 15 positive samples vs 19 if I count any segment (see code below)
#This result is reported in Results: Whole-segment amplification/sequencing yielded more positive samples than M-segment RT-qPCR

#We count as positive the samples that had at least one read matching avian influenza virus genomes database
table(aiv_filtration[1:38, ]$avian_read_matches > 0)
#FALSE  TRUE 
#19    19 

#Are they largely the same samples?
table(subset(aiv_filtration[1:38, ], avian_read_matches > 0, select = `Sample Label`))
#A1 Fltrd RXD A2 SW Unfltrd   A3 Fltrd GE  A3 Fltrd RXD  A4 Fltrd RXD  A5 Fltrd RXD A5 SW Unfltrd 
#1             1             1             1             1             1             1 
#B1 SW Unfltrd  B2 Fltrd RXD B2 SW Unfltrd B3 SW Unfltrd B4 SW Unfltrd  B5 Fltrd RXD B5 SW Unfltrd 
#1             1             1             1             1             1             1 
#C1 Fltrd RXD C1 SW Unfltrd C3 SW Unfltrd  C5 Fltrd RXD C5 SW Unfltrd 
#1             1             1             1             1 

#Yep! Including all read matches added 4 positives: A5 SW Unfltrd, B2 Fltrd RXD, C1 Fltrd RXD, and C1 SW Unfltrd 

#Is there any evidence of identical or similar sequences across samples? No. See analysis in checking_similar_sequences.sh

#Let's do a quick sanity check that this is all working properly
#One way to check is to look at reads here vs AIV filtration

#How many  matches do I have here compared to the original aiv_filtration dataframe?
sequence_check <- group_by(sequence_match_info_samples, `Sample Label`) %>%
  summarise(
    count = n(),
  )
aiv_filtration_check  <- subset(aiv_filtration, filtration != "NA" & avian_read_matches > 0, select = c("Sample Label", "avian_read_matches"))

#Join
check <- inner_join(aiv_filtration_check, sequence_check)
which(check$avian_read_matches != check$avian_read_matches)
#integer(0)
#They're the same, we're good

#Check out distribution of subtypes
sequence_match_info_samples_subtypes <- subset(sequence_match_info_samples, segment == 4 | segment == 6)

#Overall subtype distribution Figure 7 in the text
figure7 <- ggplot(sequence_match_info_samples_subtypes, aes(x = subtype, fill = segment)) + geom_histogram(stat = "count")
figure7
ggsave("figure7.pdf", figure7)

#Sumary stats
group_by(sequence_match_info_samples_subtypes, segment, subtype) %>%
  summarise(
    count = n(),
  )
# A tibble: 5 x 3
# Groups:   segment [?]
#segment subtype count
#<chr>   <chr>   <int>
#1 4       H7N9       59
#2 6       H10N6       4
#3 6       H3N6        1
#4 6       H4N6      387
#5 6       mixed       3

#Now let's look at hosts
#Let's add location
location <- NULL
location[grep("^A", sequence_match_info_samples$`Sample Label`)] <- "A. Butte county wetland"
location[grep("^B", sequence_match_info_samples$`Sample Label`)] <- "B. Yolo bypass wildlife area"
location[grep("^C", sequence_match_info_samples$`Sample Label`)] <- "C. Yolo bypass wildlife area"

#Let's clean up the repeat names due to minor mispellings
table(sequence_match_info_samples$host)

sequence_match_info_samples$host <- gsub("Blue Winged Teal", "Blue-Winged Teal", sequence_match_info_samples$host)
sequence_match_info_samples$host <- gsub("American Green-Winged Teal", "Green-Winged Teal", sequence_match_info_samples$host)
sequence_match_info_samples$host <- gsub("^Pintail$", "Northern Pintail", sequence_match_info_samples$host)

#Test
#View(cbind(sequence_match_info_samples, location))

sequence_match_info_samples <- cbind(sequence_match_info_samples, location)

group_by(sequence_match_info_samples, segment) %>%
  summarise(
    count = n(),
    mean = mean(percent_id, na.rm = TRUE),
    sd = sd(percent_id, na.rm = TRUE)
  )
# A tibble: 6 x 4
#segment count  mean    sd
#<chr>   <int> <dbl> <dbl>
#1 2          87  91.0  2.13
#2 3          14  89.3  2.38
#3 4          59 100    0   
#4 6         395  90.6  2.36
#5 7         392  92.0  3.12
#6 8          21  83.8  2.61

group_by(sequence_match_info_samples, segment) %>%
  summarise(
    count = n(),
    mean = mean(alignment_length, na.rm = TRUE),
    sd = sd(alignment_length, na.rm = TRUE)
  )
# A tibble: 6 x 4
#segment count   mean      sd
#<chr>   <int>  <dbl>   <dbl>
#1 2          87 2228.  354.   
#2 3          14  159.   22.0  
#3 4          59   28.1   0.254
#4 6         395 1445.   93.0  
#5 7         392 1001.   94.6  
#6 8          21  830.  157.

#Now look at hosts of the sequences matched in the database
host_counts_sequence_match <- subset(sequence_match_info_samples, alignment_length > 500) %>%
  group_by(host) %>%
  summarise(n = n())

#Hosts overall, ordered. This is main panel in Figure 8 in the text
figure8 <- ggplot(host_counts_sequence_match, aes(x = host, y = n)) + geom_bar(aes(reorder(host, n), n), stat = "identity") + coord_flip()
figure8
ggsave("figure8.pdf", figure8)

#Ok. Now Plot the Hosts, but by site
#Make a data frame by site ordered
host_counts_site_sequence_match <-subset(sequence_match_info_samples, alignment_length > 500) %>%
  group_by(host, location) %>%
  summarise(n = n())

#Plot by site ordered
ggplot(host_counts_site_sequence_match, aes(x = host, y = n)) + geom_bar(aes(reorder(host, n), n), stat = "identity") + coord_flip() + facet_wrap(~ location, scales = "free_x")

#By Site ordered, exclude hosts that are only represented by 1 or 2 matches
figure8_inset <- ggplot(subset(host_counts_site_sequence_match, n > 2), aes(x = host, y = n)) + geom_bar(aes(reorder(host, n), n), stat = "identity") + coord_flip() + facet_wrap(~ location, scales = "free_x")
figure8_inset
ggsave("figure8_inset.pdf", figure8_inset)

## These summary statistics are found in paper under Results: "California Wetlands Harbor Avian Viruses from Multiple Potential Host Origins and Subtypes"  
#Total host matches that have 
sum(host_counts_sequence_match$n)
#[1] 885

#How many hosts identified? Remember this dataframe is grouped by hosts so, rows == # of hosts
nrow(host_counts_sequence_match)
#[1] 26

#Sort hosts and get the percentage of total matches by the top 5 hosts
(sort(host_counts_sequence_match$n, decreasing = TRUE)[1:5] / sum(host_counts_sequence_match$n))*100
#[1] 42.372881 20.790960 17.853107  7.570621  3.163842

#Top 5 summed percentages
sum(sort(host_counts_sequence_match$n, decreasing = TRUE)[1:5] / sum(host_counts_sequence_match$n))*100
#[1] 91.75141
