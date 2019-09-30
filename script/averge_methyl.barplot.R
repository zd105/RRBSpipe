### This is script for barplot of genome-wide methylation level of C, CG, CHG and CHH ####
### Author: zhangdu
### date:   2018-08-13
### version:v1.0

arg <- commandArgs(T) 
if(length(arg) < 2){ 
	cat("Argument: 04.all.averge_methyl.xls averge_methyl.pdf\n") 
	quit('no') 
} 


tab<-read.table(arg[1],header=T,skip=1)
library(tidyr)
library(ggplot2)

tab_long<-gather(tab,Type,Average_Methylation_level,C:CHH)
pdf(file= arg[2],width=8,height=6)
ggplot(data = tab_long, mapping = aes(x = Type, y =Average_Methylation_level , fill = SampleID)) +
	geom_bar(stat="identity",position = "dodge",colour="black") +
	#geom_text(aes(label=round(Average_Methylation_level,4)), vjust= -1, position = position_dodge(0.9), size=3.5) +
	#scale_fill_brewer(palette="Dark2") + 
	ggtitle("Genome-wide average methylation of total C, CG, CHG and CHH") 
dev.off()
