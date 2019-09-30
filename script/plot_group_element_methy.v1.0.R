# A script for mutisamples vioplot of element methy
# author: zhangdu
# date: 2018-8-14

args<-commandArgs(T) 
if(length(args) < 3){ 
	cat("Argument: all.sample.genome.cgi.methy.txt all.sample.genome.cgi.methy_vioplot CGI\n") 
	quit('no') 
} 
infile<-args[1]
outpdf<-args[2]
element<-args[3]

library(ggplot2)
tab<-read.table(infile,header=F)
colnames(tab)<-c("Group","Sample_ID","Methylation_level")
tab$Methylation_level<-as.numeric(as.vector(tab$Methylation_level))
#group plot
m<-length(levels(factor(tab$Group)))
pdf(file=outpdf)
ggplot(tab, aes(x=Group, y=Methylation_level)) +
geom_violin(fill="green4",size=0.5) +
geom_boxplot(width=0.01,fill="black",outlier.size=0,size=0.5) +
theme_minimal() +
stat_summary(fun.y=median, geom="point", size=1,shape=21,fill="white") +
theme(axis.text.x = element_text(angle = -45,hjust = 0.5, vjust=0.5)) +
theme(panel.border = element_rect(fill = NA)) +
labs(title = paste("Group methylation level distribution of",element,sep=" "))
dev.off()

