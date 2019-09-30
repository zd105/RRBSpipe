### This is script for pieplot of Genome C, CHG and CHH count percentage ####
### Author: zhangdu
### date:   2018-08-13
### version:v1.0

arg <- commandArgs(T) 
if(length(arg) < 2){ 
	cat("Argument: 05.all.coverage_depth.xls methy_type.pieplot.pdf\n") 
	quit('no') 
} 

library(tidyr)
library(ggplot2)
tab<-read.table(arg[1],header=T,skip=1)
tab<-tab[1,]
tab1<-data.frame(CG=tab$total_CG,CHG=tab$total_CHG,CHH=tab$total_CHH)
tab_long<-gather(tab1,Type,Number,CG:CHH)

tab_long = tab_long[order(tab_long$Number, decreasing = TRUE),]
myLabel = as.vector(tab_long$Type)   
tab_long$Number<-as.numeric(tab_long$Number)
myLabel = paste(myLabel, "(",tab_long$Number,",",round(tab_long$Number / sum(tab_long$Number) * 100, 2), "%)", sep = "")   

pdf(arg[2])
  ggplot(tab_long, aes(x = "", y = Number, fill = Type)) +
  geom_bar(stat = "identity", color="white", width = 1) +    
  coord_polar(theta = "y") + 
  labs(x = "", y = "", title = "") + 
  theme(axis.ticks = element_blank()) + 
  theme(legend.title = element_blank(), legend.position = "top") + 
  scale_fill_discrete(breaks = tab_long$Type, labels = myLabel) + 
  #scale_fill_brewer(palette="Dark2") +
  theme(axis.text.x = element_blank()) +
  theme(panel.grid=element_blank()) +    ## 去掉白色圆框和中间的坐标线
  theme(panel.border=element_blank()) + ## 去掉最外层正方形的框框
  theme(panel.background = element_blank())+
  ggtitle("Genome C, CHG and CHH percentage") 

dev.off()
