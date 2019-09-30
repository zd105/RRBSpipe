#### usage
#  Rscript this.R input.mat(with col.names) prefix.of.output
#  pca  analysis for each col of input.file
####

#####
args <- commandArgs(TRUE)
input.file <- args[1]
prefix <- args[2]

######
rt <- read.table(file=input.file, header=T)
rt <- t( as.matrix( rt ) )



######
pdf(file= paste(prefix, ".pdf", sep=""), height=6, width=10)

plot( hclust( dist( rt ) ) )

dev.off()
