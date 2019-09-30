args <- commandArgs(T)
indir <- args[1]
elementlist <- args[2]
outprefix <- args[3]
sample <- args[4]

elementlist1<- unlist(strsplit(elementlist,split="-"))
#elementlist2<-paste("genome",elementlist1,"methy.txt",sep=".")
#elementdir <- paste(indir,elementlist2,sep="/")

a <- matrix(c(1,1),nrow=1)
for(i in elementlist1){
	elementlist2<-paste(sample,"Repeats",i,"methy.txt",sep=".")
	elementdir <- paste(indir,elementlist2,sep="/")
	print(paste("Reading methylation information:",i,sep=" "))
	x1<-read.table(elementdir)
	x1<-as.matrix(x1)
	xa<-x1[,ncol(x1)]
	xb<-matrix(xa,ncol=1)
	a<- rbind(a,cbind(i,xb))
}

#col <- rainbow(length(elementlist1))
colo <- c("red3","green4","yellow3","purple3","blue3","orange3","pink3","deepskyblue","grey")
color <- colo[1:length(elementlist1)]
a <-a[-1,]
colnames(a)<-c("Element","Methylation_level")
a <- na.omit(a)
a <- as.data.frame(a)

#write.table(a,file="plot.txt")
#a<-read.table("plot.txt")

library(ggplot2)
pdf(file=paste(outprefix,"boxplot.pdf",sep="."))
a$Methylation_level<-as.numeric(as.vector(a$Methylation_level))
ggplot(a, aes(x=Element, y=Methylation_level,fill=Element)) +
geom_boxplot(outlier.size=0.0015,outlier.alpha=0.3,outlier.color="red") +
theme_minimal() +
stat_summary(fun.y=median, geom="point", size=2,shape=22,fill="white") +
 #annotate("text", label = paste("DMR = ",n), x = 2, y = 1, size = 5) +
theme(panel.border = element_rect(fill = NA)) +
theme(axis.text.x = element_text(angle = 45,hjust = 1)) +
labs(title = paste("Sample",sample,"element methylation level distribution",sep=" "))

dev.off()

pdf(file=paste(outprefix,"density_plot.pdf",sep="."))
p <- ggplot(a, aes(x=Methylation_level))
p <- p + geom_density(aes(fill=Element,color=Element),alpha=0.6)
p <- p + facet_grid(Element~.)
p
dev.off()

pdf(file=paste(outprefix,"density_plot.pdf",sep="."))
p <- ggplot(a, aes(x=Methylation_level))
p <- p + geom_density(aes(fill=Element,color=Element),alpha=0.6)
p <- p + facet_grid(Element~.)
p
dev.off()

pdf(file=paste(outprefix,"vioplot.pdf",sep="."))
e <- ggplot(data = a, aes(x=Element, y=Methylation_level))
e <- e + geom_violin(alpha=0.4,aes(fill=Element,color=Element))
e + geom_boxplot(width=0.01,outlier.size=0.0005,outlier.alpha=0.3,outlier.color="red")
dev.off()

library(ggridges)
pdf(file=paste(outprefix,"ridges.pdf",sep="."))
ggplot(a, aes(x=Methylation_level, y=Element, fill=..x..))+
    geom_density_ridges_gradient(scale=3, rel_min_height=0.01, gradient_lwd = 1.)+
    scale_x_continuous(breaks=seq(0,1,0.1))+
    scale_y_discrete(expand = c(0.01,0))+
    labs(title=paste("Sample",sample,"element methylation level distribution",sep=" "))+
    theme_ridges(font_size = 13, grid = FALSE)+
    theme(axis.title.y = element_blank())
dev.off()

pdf(file=paste(outprefix,"ridges2.pdf",sep="."))
ggplot(a, aes(x=Methylation_level, y=Element, fill=Element))+
    geom_density_ridges(scale=4,alpha=0.4)+
    scale_x_continuous(breaks=seq(0,1,0.1))+
    scale_y_discrete(expand = c(0.01,0))+
    scale_fill_cyclical(values = colo)+
    labs(title=paste("Sample",sample,"element methylation level distribution",sp=" "))+                                                   
    theme_ridges(font_size = 13, grid = FALSE) +
    xlim(0,1)+
    theme(axis.title.y = element_blank())
dev.off()

