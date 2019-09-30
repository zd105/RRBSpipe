################
# 绘制平均甲基化水平与测序深度之间的关系曲线图
# 用法：
#     z01.accu_cover.R infile outfile maxpotdepth
# 输入文件格式：
#########################################
##Depth	CG	CHG	CHH
#1	1	1	1
#2	0.95060021	0.95155783	0.95493366
#3	0.91336506	0.91503184	0.92008996
#4	0.88390236	0.88590425	0.89146675
##########################################


args <- commandArgs(T)
file <- args[1]
outpdf <- args[2]
maxpotdepth <-as.numeric(args[3])

rt <- read.table(file=file)
pdf(file=outpdf, height=4, width=6)
par(mar=c(5,5,5,4), las=1)
plot(rt[,1], rt[,2] * 100, type="l", lwd=2, col="royalblue", xlim=c(1,maxpotdepth), 
    xlab=" >= Sequencing Depth ", ylab="Coverage (%)", main="Accumulated Coverage")
points(rt[,1], rt[,3] * 100, type="l", lwd=2, col="firebrick")
points(rt[,1], rt[,4] * 100, type="l", lwd=2, col="gold")
legend("topright", c("CG", "CHG", "CHH"), col=c("royalblue", "firebrick", "gold"), lwd=2)
dev.off()
