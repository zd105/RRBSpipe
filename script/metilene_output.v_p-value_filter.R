#!/usr/local/bin/Rscript

#########################################
### This is a p-value fiter version of metilene_output.R
###
### Author: zhangdu
###
### Usage:  Rscript metilene_output.v_p-value_filter.R <dmr.txt> <outprefix> <group1 name> <group2 name>
#########################################

args <- commandArgs(trailingOnly = TRUE)


## Loading packages
library(ggplot2)

## make nice plots
theme_cfg <-
  theme_bw() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_blank(),

    axis.line = element_line(colour = "black"),

    legend.key = element_blank()
  )

## Read input file
data <- read.table(file=args[1], header=F, col.names=c('chr','start','end','p_val','diff','CpG','group1','group2'))
data$length <- data$end-data$start

## Plot statistics
#pdf(args[2])
# 01 difference histogram
pdf(file = paste(args[2],"DMR_difference_histogram.pdf",sep="."),width =5,height=5)
ggplot(data, aes(x=diff)) + geom_histogram(binwidth=0.05, fill='steelblue3', color='black') + xlab("Mean methylation difference")  + scale_x_continuous(limits=c(-1,1)) + labs(title=paste(args[3],"vs",args[4],"DMR difference histogram",sep=" "))
# + theme_cfg
dev.off()

# 02 length distribution CpGs
pdf(file = paste(args[2],"DMR_mC_length_distribution.pdf",sep="."),width =5,height=5)
ggplot(data, aes(x=length, fill = 'skyblue3')) + geom_line(stat="Density", size=1) + xlab("DMR length [nt]") + labs(title=paste(args[3],"vs",args[4],"DMR length distribution(mC)",sep=" "))
#+ theme_cfg
dev.off()

# 03 length distribution nt
pdf(file = paste(args[2],"DMR_nt_length_distribution.pdf",sep="."),width =5,height=5)
ggplot(data, aes(x=CpG)) + geom_line(stat="Density", size=1) + xlab("DMR length [CpG]") + labs(title=paste(args[3],"vs",args[4],"DMR length distribution(nt)",sep=" "))
#+ theme_cfg
dev.off()

# 04 p_val vs difference
pdf(file = paste(args[2],"DMR_p_val-difference.pdf",sep="."),width =5,height=5)
ggplot(data, aes(x=diff, y=p_val)) + geom_point(alpha=.5) + scale_y_log10() + xlab("Mean methylation difference") + ylab("p-value") + labs(title=paste(args[3],"vs",args[4],"DMR p_val-difference",sep=" "))
#+ theme_cfg
dev.off()

# 05 mean1 vs mean2

pdf(file = paste(args[2],"DMR_methylation_distribution.pdf",sep="."),width =5,height=5)
ggplot(data, aes(x=group1, y=group2)) + geom_point(alpha=.5) + coord_fixed() + xlab(args[3]) + ylab(args[4]) + labs(title=paste(args[3],"vs",args[4],"DMR methylation Level distribution",sep=" "))
# + theme_cfg
dev.off()

# 06 nt vs CpGs
pdf(file = paste(args[2],"DMR_nt-mC_number.pdf",sep="."),width =5,height=5)
ggplot(data, aes(x=length, y=CpG)) + geom_point(alpha=.5) + xlab("DMR length [nt]") + ylab("DMR length [CpGs]") + labs(title=paste(args[3],"vs",args[4],"DMR nt-mC number",sep=" "))
#+ theme_cfg
dev.off()

# 07 DMR scatter plot
 pdf(file = paste(args[2],"DMR_scatter_plot.pdf",sep="."),width =5,height=5)
n <- nrow(data)
ggplot(data, aes(x = group1, y = group2)) + 
geom_point(alpha=0.5,colour="#0000FF") + 
stat_density_2d(aes(alpha=..density..,fill = ..density..), geom = "tile",contour=FALSE)+
scale_fill_gradientn (colours = c("#FFFFFF", "#0000FF","#00FF00","#FFFF00","#FF0000")) + 
labs(title=paste("DMR methylation Level distribution(n=",n,")",sep="")) + xlab(args[3]) + ylab(args[4]) +
theme(plot.title = element_text(hjust = 0.5),panel.background=element_blank(),panel.border=element_rect(fill=NA),legend.position="none") + 
scale_y_continuous(limits=c(0,1),expand = c(0,0)) + 
scale_x_continuous(limits=c(0,1),expand = c(0,0))
dev.off()


# 08 DMR violin plot
library("vioplot")
### T.test ###
xa<-data$group1
xb<-data$group2
ya<-xa[!is.na(xa)]
yb<-xb[!is.na(xb)]
ylim<-max(ya,yb)
maxy=ylim
p=signif(t.test(xa,xb)$p.value,digits=4)
plot.new=TRUE
main=paste("n=",n," P=",p,seq="")
### Plot figure ###
 pdf(file = paste(args[2],"DMR_violin_plot.pdf",sep="."),width =5,height=5)
vioplot(xa,xb,names=c(args[3],args[4]),col="gold",ylim=c(0,maxy))
title(main)
dev.off()


