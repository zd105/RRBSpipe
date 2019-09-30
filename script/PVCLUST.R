########################################
### usage Rscript this.R input.mat ouput.pdf
### pvclust for each col of input.mat
########################################
args <- commandArgs(T)
inputfile <- args[1]
output.pdf <- args[2]

x <- read.table(file=inputfile, header=T)
x <- as.matrix(x)

library(pvclust)

# method.hclust -> "average", "ward", "single", "complete", "mcquitty", "median" or "centroid"
#                  "ward", "single", "complete", "average", "mcquitty", "median" or "centroid"
# method.dist   -> "correlation", "uncentered", "abscor"
#                  "euclidean", "maximum", "manhattan", "canberra", "binary" or "minkowski"
# use.cor       -> "pairwise.complete.obs", "all.obs" or "complete.obs"
## pvclust(data,
#    method.hclust="average",
#    method.dist="correlation",
#    use.cor="pairwise.complete.obs",
#    nboot=1000,
#    r=seq(.5,1.4,by=.1),
#    store=FALSE,
#    weight=FALSE)


x.pv <- pvclust(x, nboot = 100)

pdf(file=output.pdf, height=6, width=10)

plot(x.pv, cex=1, cex.pv=0.8)

dev.off()

#####

