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
n<-length(levels(factor(tab$Sample_ID)))
tab$Methylation_level<-as.numeric(as.vector(tab$Methylation_level))
#all sample plot
pdf(file=paste("all.sample",outpdf,sep="."),height=5,width=0.7*n)
ggplot(tab, aes(x=Sample_ID, y=Methylation_level)) +
geom_violin(fill="deepskyblue",size=0.5) +
geom_boxplot(width=0.6/n,fill="black",outlier.size=0,size=0.5) +
theme_minimal() +
stat_summary(fun.y=median, geom="point", size=15/n,shape=21,fill="white") +
theme(axis.text.x = element_text(angle = -45,hjust = 0.5, vjust=0.5)) +
theme(panel.border = element_rect(fill = NA)) +
labs(title = paste("Sample methylation level distribution of",element,sep=" "))
dev.off()
#group plot
m<-length(levels(factor(tab$Group)))
pdf(file=paste("all.group",outpdf,sep="."),height=5,width=0.2*m)
ggplot(tab, aes(x=Group, y=Methylation_level)) +
geom_violin(fill="green4",size=0.5) +
geom_boxplot(width=0.05/m,fill="black",outlier.size=0,size=0.5) +
theme_minimal() +
stat_summary(fun.y=median, geom="point", size=10/m,shape=21,fill="white") +
theme(axis.text.x = element_text(angle = -45,hjust = 0.5, vjust=0.5)) +
theme(panel.border = element_rect(fill = NA)) +
labs(title = paste("Group methylation level distribution of",element,sep=" "))
dev.off()

