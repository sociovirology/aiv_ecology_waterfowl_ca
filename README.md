# Viral Ecology of Avian Influenza of Waterfowl in the Central Valley of California using MinION Sequencing
This github repository includes code (and links to data) from the manuscript:  
"Prevalence and Viral Ecology of Avian Influenza of Waterfowl in the Central Valley of California"  
Madeline M. McCuen | Maurice E. Pitesky | Jeff J. Buler | Sarai Acosta | Alexander Wilcox | Ronald F. Bond | Samuel L. Díaz-Muñoz

If you are reading or using this, let us know how these data were useful for you. If you use these data and code, please cite the repository or the paper. Always open to collaborate! Please contact us!

### Quick Start
1. Make sure packages are installed (see #2 below)
2. git clone 
3. chmod +x 
4. ./
5. Rscript a (or load interactively in R)


### CONTENTS
1. Project Description
2. Packages and software used to test code
3. Data
4. Code

### 1. Project Description
Abstract:
Exposure to Avian Influenza (AIV) is a significant concern to the commercial poultry industry. Waterfowl are the primary reservoir of the virus, therefore understanding the presence/absence and type of AIV in waterfowl is essential toward mitigating risk. Here we determine the presence/absence and viral ecology of AIV in the birds themselves, in determined high waterfowl density wetlands. Specifically, a total of 175 oropharyngeal/cloacal samples were collected, amplified, and sequenced during the summer of 2021 from waterfowl within five wetlands located on the Sacramento National Wildlife Refuge Complex. Results will be used to provide a new layer of data for the CWT which allows stakeholders to identify the presence/absence of waterfowl near their farms. With this new layer of data, the CWT will be more applicable and accessible to poultry producers throughout the central valley of California. 

### 2. Packages and software used to test code
This code was tested using the following software packages:

* 
* 
* 
* 


### 3. Data
Data consists of sequencing output from the Oxford Nanopore Technologies MinION sequencer platform (FASTQ files), sample information, gels, and Influenza Research Database FASTA files, and sample barcodes

1) Sequencing file will be available in the Sequence Read Archive

2) Sample information is in: 

4) Primer and barcode information is in data/illumina_fwd.fasta and data/illumina_rev.fasta

5) Database file of all avian influenza sequences in FluDB in data/all_avian_flu.fasta.gz (used in minion_demultiplexing_flu_assignment.sh)
