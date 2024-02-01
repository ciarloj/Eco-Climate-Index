# Install pre-requisite packages
#install.packages("stats")
#install.packages("dplyr")

# Load required libraries
library(stats)
suppressPackageStartupMessages(library('dplyr'))

args <- commandArgs(trailingOnly = TRUE)
#print(args)
args_splt = strsplit(args, " ")
#print(args_splt)
flog <- args_splt[[1]][1]
idir <- args_splt[[1]][2]
#print(flog)
#print(idir)

# Load data
file1 <- paste(idir, flog, sep="/")
file <- paste(file1, ".csv", sep="")
#print(file)
my_data <- read.csv(file, header = TRUE, sep = " ", dec = ".")
#set missing values to NA
#head(my_data)
my_data[my_data >= 99999999] <- NA
#head(my_data)

# convert character values to numeric
#names(my_data)
#str(my_data)
dims = dim(my_data)
ncol = dims[2]
cnam = colnames(my_data)[4:ncol]
nm_data <- my_data[1:3]

#head(my_data[1:6], n=10)

for (i in 4:ncol){
  #print(i)
  vnam = colnames(my_data)[i]
  cch = my_data[vnam]
  cch[cch=="_"] <- NA
  nnn <- as.numeric(unlist(cch))
  nm_data[vnam] <- nnn
}

#ead(nm_data[1:6], n=10)
#dcor <- cor(nm_data[4:ncol], use="complete.obs")
#acor <- mean(abs(dcor))
#print(paste("absolute mean correlation of variables: ",acor))

# Check if mean is above 0.3
#rint(dcor)
#min(abs(dcor))

#Execute Principal Component Analysis
PCA <- princomp(na.omit(nm_data[4:ncol]))
summary(PCA)
#sPC <- summary(PCA)
#vs <- as.data.frame.matrix(sPC)


#PCL <- PCA$loadings
#PC = PCA$scores
#ss = as.data.frame.matrix(PC)
##head(PC)

##print("correlation of all components...")
##cor(PC)
##print(PCL)
#dd = as.data.frame.matrix(PCL)
#threshold <- 0.1
#dd[abs(dd) < threshold] <- NA
##print(dd)
#ncomp <- ncol(dd)
#pathnw = paste(idir, "pca", sep="/")
#pathfl = paste(pathnw, flog, sep="/")
#compf1 = paste(pathfl, "_comp", sep="")
#
#compsf = paste(pathfl, "_scores.csv", sep="")
#write.csv(ss, file=compsf)
#
#for (n in 1:ncomp){
#  compf2 = paste(compf1, n, sep="")
#  compfl = paste(compf2, ".csv", sep="")
#  compid = paste("Comp.", n, sep="")
#  write.csv(dd[compid], file=compfl)
# #print(dd["Comp.1"])
#}

