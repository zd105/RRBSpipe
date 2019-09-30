args <- commandArgs(T)
file <- args[1]
chr <- args[2]
outpdf <- args[3]

#####
rt <- read.table(file=file)
pdf(file=outpdf, height=6, width=17)
   par(mar=c(4,6,5,6), las=1) 
   plot(0, type="n",
       xlab="", xlim=c(0, rt[nrow(rt),1]),
       ylim=c(-1, 1), ylab="CpG methylation level", 
       bty="n", yaxt="n",
       main=chr)
   abline(h=0)
   axis(2, at=c(-1, -0.8, -0.6, -0.4, -0.2, 0, 0.2, 0.4, 0.6, 0.8, 1),
     lab=c(1, 0.8, 0.6, 0.4, 0.2, 0, 0.2, 0.4, 0.6, 0.8, 1), 
     col="royalblue")
   axis(4, at=c(-1, -0.8, -0.6, -0.4, -0.2, 0, 0.2, 0.4, 0.6, 0.8, 1),
     lab=c(100, 80, 60, 40, 20, 0, 20, 40, 60, 80, 100), 
     col="green3")
   mtext(side=4, "GC content (%)", las=3, line=3)
   
   points(rt[,1], rt[,2], type="h", col=rgb(0.2,0.8,0.2,0.1),  lwd=0.1, lend=2)
   points(rt[,1], -rt[,2], type="h", col=rgb(0.2,0.8,0.2,0.1), lwd=0.1, lend=2)
   
   ## CG
   s<-smooth.spline(rt[,1], rt[,3],df=100)
   points(rt[,1], s$y, type="l", col="royalblue", lwd=2, xpd=T)
   s<-smooth.spline(rt[,1], -rt[,6],df=100)
   points(rt[,1], s$y, type="l", col="royalblue", lwd=2, xpd=T)

   ## CHG
   s<-smooth.spline(rt[,1], rt[,4],df=100)
   points(rt[,1], s$y, type="l", col="firebrick", lwd=2, xpd=T)
   s<-smooth.spline(rt[,1], -rt[,7],df=100)
   points(rt[,1], s$y, type="l", col="firebrick", lwd=2, xpd=T)

   ## CHH
   s<-smooth.spline(rt[,1], rt[,5]*50,df=100)
   points(rt[,1], s$y, type="l", col="gold", lwd=2, xpd=T)
   s<-smooth.spline(rt[,1], -rt[,8]*50,df=100)
   points(rt[,1], s$y, type="l", col="gold", lwd=2, xpd=T)

   legend("topright", c("CG", "CHG", "CHH"), col=c("royalblue", "firebrick", "gold"), lwd=2,bty="n")
dev.off()
