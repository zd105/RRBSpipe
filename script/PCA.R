#### usage
#  Rscript this.R input.mat(with col.names) class.file  prefix.of.output
#  pca  analysis for each col of input.file
####

#####
args <- commandArgs(TRUE)
input.file <- args[1]
class.file <- args[2]
prefix <- args[3]

######
rt1 <- read.table(file=input.file, header=T)
rt1 <- t( as.matrix( rt1 ) )

rt2 <- read.table(file=class.file)
class <- as.character( rt2[,1] )

######
library(ade4)
pca <- prcomp(rt1)
s <- summary(pca)
write.table(pca$x, paste(prefix,".x.txt",sep=""), quote = F, sep="\t")
write.table(s$importance, paste(prefix,".eig.txt",sep=""), quote = F, sep="\t")

######
fac <- as.factor(class)
fac.len <- length(levels(fac))
colo <- c("red3", "green4","yellow3",
          "purple3","blue3","orange3",
          "pink3","deepskyblue","black")

pdf(file= paste(prefix, ".pdf", sep="") )
par(mfrow=c(2,2))

kip <- s$importance


plot(pca$x[, 1:2], type="n",xlab="",ylab="")
text(pca$x[, 1:2], rownames(rt1), adj=c(1,1), pos=1, cex=0.6)
title(xlab=paste("PC1(",round(kip[2,1]*100,2),"%)"),ylab=paste("PC2(",round(kip[2,2]*100,2),"%)"))
s.class(pca$x[, 1:2], fac, col=colo[1:fac.len], include.origin=FALSE, cpoint=1, addaxes=TRUE, cstar=1, add.plot = TRUE)

plot(pca$x[, 2:3], type="n",xlab="",ylab="")
text(pca$x[, 2:3], rownames(rt1), adj=c(1,1), pos=1, cex=0.6)
title(xlab=paste("PC2(",round(kip[2,2]*100,2),"%)"),ylab=paste("PC3(",round(kip[2,3]*100,2),"%)"))
s.class(pca$x[, 2:3], fac, col=colo[1:fac.len], include.origin=FALSE, cpoint=1, addaxes=TRUE, cstar=1, add.plot = TRUE)

plot(pca$x[, c(1,3)], type="n",xlab="",ylab="")
text(pca$x[, c(1,3)], rownames(rt1), adj=c(1,1), pos=1, cex=0.6)
title(xlab=paste("PC1(",round(kip[2,1]*100,2),"%)"),ylab=paste("PC3(",round(kip[2,3]*100,2),"%)"))
s.class(pca$x[, c(1,3)], fac, col=colo[1:fac.len], include.origin=FALSE, cpoint=1, addaxes=TRUE, cstar=1, add.plot = TRUE)

dev.off()

##########
#pca <- dudi.pca(rt1, center =TRUE, scale = TRUE, scannf = FALSE, nf=dim(rt1)[1] - 1)
#write.table(pca$eig, paste(prefix,"_eig.txt",sep=""),quote = F, sep="\t")
#write.table(pca$c1, paste(prefix,"_c1.txt",sep=""), quote = F, sep="\t")
#write.table(pca$li, paste(prefix,"_li.txt",sep=""), quote = F, sep="\t")


#kip <- 100 * pca$eig/sum(pca$eig)
#kip
#pdf(file=paste(prefix,"_2.pdf",sep=""))
#plot(pca$c1[, 1:2],ann=FALSE)
#text(pca$c1[, 1:2], colnames(rt1), adj=c(1,1), pos=1, cex=0.5)
#options(digits=2)
#title(xlab=paste("PC1(",round(kip[1],2),"%)"),ylab=paste("PC2(",round(kip[2],2),"%)"))
#s.class(pca$c1[, 1:2], fac, col=colo[1:fac.len], include.origin=FALSE, cpoint=1.2, addaxes=TRUE, cstar=1, add.plot = TRUE)
#barplot(pca$eig)
#dev.off()
#png(file=paste(prefix,"_pca.png",sep=""),width = 1024, height = 1024)
#plot(pca$c1[, 1:2],ann=FALSE)
#text(pca$c1[, 1:2], colnames(rt1), adj=c(1,1), pos=3, cex=1)
#title(xlab=paste("PC1(",round(kip[1],2),"%)"),ylab=paste("PC2(",round(kip[2],2),"%)"))
#s.class(pca$c1[, 1:2], fac, col=colo[1:fac.len], include.origin=FALSE, cpoint=3, addaxes=TRUE, cstar=1, add.plot = TRUE)
#dev.off()

