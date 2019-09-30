### This is script for pieplot of DMR annotation results ####
### Author: zhangdu
### date:   2018-08-14
### version:v1.0

arg <- commandArgs(T) 
if(length(arg) < 2){ 
	cat("Argument: **.annotate.xls DMR_annotate.pdf\n") 
	quit('no') 
} 
library(dplyr)
library(ggplot2)
tab<-read.table(arg[1],header=T)
tab1<-tab[,9:15]
total<-nrow(tab1)

x0 <- apply(tab1,1,function(i) sum(i=="--")==length(i))
tab2<-tab1[x0,]
unanno<-nrow(tab2)

## stat the annotation results:
aa<-data.frame(promoter=nrow(filter(tab1,!promoter %in% "--")),
               up2k=nrow(filter(tab1,!up2k %in% "--")),
			   down2k=nrow(filter(tab1,!down2k %in% "--")),
			   genebody=nrow(filter(tab1,!genebody %in% "--")),
			   exon=nrow(filter(tab1,!exon %in% "--")),
			   intron=nrow(filter(tab1,!intron %in% "--")),
			   cgi=nrow(filter(tab1,!cgi %in% "--")),
			   other_region=unanno
			   )
rownames(aa)<-"Number"
aa1<-t(aa)
aa1<-as.data.frame(aa1)
aa1$Element<-colnames(aa)
aa1 = aa1[order(aa1$Number, decreasing = TRUE),]
aa1$Number<-as.numeric(aa1$Number)
aa1$Percent<-paste(round(aa1$Number / total * 100, 2), "%", sep = "")
aa1 <- select(aa1, Element, everything())
write.table(aa1,file=paste(arg[2],"stat.xls",sep="."),row.names=F,col.names=T,sep="\t",quote=F)


# plot
myLabel = as.vector(aa1$Element)
myLabel = paste(myLabel, "(",aa1$Number," DMRs,",round(aa1$Number / sum(aa1$Number) * 100, 2), "%)", sep = "")

M<-max(aa1$Number)

#barplot
pdf(paste(arg[2],"barplot.pdf",sep="_"))
  ggplot(aa1, aes(x=Element,y=Number,fill = Element)) +
  geom_bar(stat="identity",width=0.9,color="black")+
  #coord_polar(theta = "y",start=0)+
  scale_fill_discrete(breaks = aa1$Element, labels = myLabel)+
  #scale_fill_brewer(palette="Greens")+
  guides(fill = guide_legend(reverse = TRUE))+
  geom_text(aes(label=Number), vjust=1.5, color="white",position = position_dodge(0.9), size=3.5)+
  theme(axis.text.x = element_text(angle = 45,hjust = 1)) +
  #expand_limits(m)+
  theme(
  #    panel.grid = element_blank(),
      panel.background = element_blank(),
  #    axis.text.y = element_blank(),
  #    axis.ticks= element_blank(),
  #    axis.title = element_blank()
  )+
  labs(y="Annotated DMR Number",title="DMR annotation results") 

dev.off()

# rose plot
pdf(paste(arg[2],"roseplot.pdf",sep="_"))
  ggplot(aa1, aes(x=Element,y=Number,fill = Element)) +
  geom_bar(stat="identity",width=0.95)+
  coord_polar(theta = "x",start=0)+
  scale_fill_discrete(breaks = aa1$Element, labels = myLabel)+
  guides(fill = guide_legend(reverse = TRUE))+
  geom_text(aes(label=Number), vjust=-1.5, color="black",position = position_dodge(0.9), size=3.5)+
  #expand_limits(-M/5)+
  ylim(c(-M/5,M))+
  theme(
        panel.grid = element_blank(),
		panel.background = element_blank(),
		axis.text.y = element_blank(),
		axis.ticks= element_blank(),
		axis.title = element_blank()
		)+
  labs(title="DMR annotation results")
dev.off()

