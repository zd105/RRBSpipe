# A script for stack barplot of methylation data
# zhangdu
# 2018-8-13
# v1.0

# USAGE:
# Rscript methy_stat_bar.R in 5 out_prefix
# "5" is the number of stack blocks for each bar to plot.

# in file format:
############################
#Group	A	A	B	B
#Sample	s1	s2	s3	s4
#rowname1	0.1	0.1	0.1	0.1
#rowname2	0.1	0.2	0.1	0.2
############################


	args <- commandArgs(TRUE)
#data <- read.table(args[1],header=T,row.names=1)
	data <- read.table(args[1])
n <- as.numeric(args[2])
	prefix <- args[3]

	grouplabels <- as.character(t(data[1,-1]))
samplelabels <- as.character(t(data[2,-1]))

#data1 is sample methy
	data1<-data[c(-1,-2),-1]
data1 <- matrix(as.numeric(as.matrix(data1)), dim(data1)[1], dim(data1)[2], byrow=F)
	rownames(data1)<-data[c(-1,-2),1]
	data2<-data1
	colnames(data1)<-samplelabels

#data3 is group methy
	colnames(data2)<-grouplabels
groups<-levels(as.factor(grouplabels))
	if(length(groups) != length(samplelabels)){
		data3<-matrix(nrow=dim(data2)[1],ncol=length(groups))
			for(i in 1:length(groups)){
				data2a<-data2[,colnames(data2)==groups[i]]
					data3[,i]<-apply(data2a,1,mean)
			}
		colnames(data3)<-groups
			rownames(data3)<-data[c(-1,-2),1]
			grouplabels1<-colnames(data3)
			write.table(data3,file=paste(prefix,"group.table",sep="_"),quote=F)
	}

# stat sample methy distribution
mat <- matrix(0,ncol=length(samplelabels),nrow=n)
	unit = 1/n
	start = 0
regions <- rep(0,n)
	for ( i in 1:n ) {regions[i]=paste( start, start+unit, sep="-"); start = start + unit }

	colnames(mat) <- samplelabels
	rownames(mat) <- regions
data1 <- ceiling(data1/unit)

	for (i in 1:length(samplelabels)){
		v = table(data1[,i])
			mat[,i]<-as.numeric(v)[2:(n+1)]
			mat[1,i] <- mat[1,i] + as.numeric(v)[1] 
	}

base = dim(data1)[1]
mat <- mat/base
write.table(mat,file=paste(prefix, "methy_distribution.xls",sep="_"),quote=F)

#plot sample methy distribution
colors <- c("red3","green4","yellow3","purple3","blue3","orange3","pink3","deepskyblue","orange","lightcyan2")

	pdf(file=paste(prefix, "stackbar.pdf",sep="_"))
par(mai=c(1.2,1,1.2,1.3),mgp=c(3.5,0.6,0),las=2)
	barplot(mat,names.arg=samplelabels,xlab="Sample",ylab="% Cpg coverage",col=colors,cex.names=0.8,cex.axis=0.8)
	xy <- par("usr")
	legend(x=xy[2]+0.1,y=xy[4]-0.1, regions, cex=0.8, fill=colors,xpd=T)
dev.off()

# stat group methy distribution
	if(length(groups) != length(samplelabels)){
		mat <- matrix(0,ncol=length(grouplabels1),nrow=n)
			unit = 1/n
			start = 0
			regions <- rep(0,n)
			for ( i in 1:n ) {regions[i]=paste( start, start+unit, sep="-"); start = start + unit }

		colnames(mat) <- grouplabels1
			rownames(mat) <- regions
			data3 <- ceiling(data3/unit)

			for (i in 1:length(grouplabels1)){
				v = table(data3[,i])
					mat[,i]<-as.numeric(v)[2:(n+1)]
					mat[1,i] <- mat[1,i] + as.numeric(v)[1]
			}

		base = dim(data3)[1]
			mat <- mat/base
			write.table(mat,file=paste(prefix, "group_methy_distribution.xls",sep="_"),quote=F)

#plot group methy distribution
			colors <- c("red3","green4","yellow3","purple3","blue3","orange3","pink3","deepskyblue","orange","lightcyan2")

			pdf(file=paste(prefix, "group_stackbar.pdf",sep="_"))
			par(mai=c(1.2,1,1.2,1.3),mgp=c(3.5,0.6,0),las=2)
			barplot(mat,names.arg=grouplabels1,xlab="Sample",ylab="% Cpg coverage",col=colors,cex.names=0.8,cex.axis=0.8)
			xy <- par("usr")
			legend(x=xy[2]+0.1,y=xy[4]-0.1, regions, cex=0.8, fill=colors,xpd=T)
			dev.off()
	}
