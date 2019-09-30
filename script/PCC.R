#### usage 
####  Rscript this.R input.mat prefix.output
####  corrplot for each col of input.mat
##########


##### lib
library(corrplot)

#####
args <- commandArgs(T)
file.input = args[1]
pdf.output = args[2]

dat <- read.table(file= file.input, header=T)

corpct <- round( as.matrix( cor( dat )) * 100, 2)

# diag(corpct) <- min(corpct)

col1 <- colorRampPalette( c("blue", "cyan", "yellow", "orange", "red") )

col2 <- colorRampPalette( c("#7F0000","red","#FF7F00",
                            "yellow","#7FFF7F", "cyan", 
                            "#007FFF", "blue","#00007F"))

col3 <- colorRampPalette( c("#67001F", "#B2182B", "#D6604D", 
                            "#F4A582", "#FDDBC7", "#FFFFFF", 
                            "#D1E5F0", "#92C5DE", "#4393C3", 
                            "#2166AC", "#053061") )

pdf(file=paste(pdf.output,"pdf",sep="."), pointsize=12)
par( xpd = NA )
corrplot( corpct,
    type= "full",# c("full", "lower", "upper")
    order= "original",    # c("original", "AOE", "FPC", "hclust", "alphabet")
    cl.lim= c(min(corpct), max(corpct) ),
    diag= FALSE,   # coefficients on the principal diagonal     
    addCoefasPercent = FALSE,
    addCoef.col = NULL,  #  NULL, add no Conrf
    tl.col= "black", 
    is.corr= F,
    method= "circle",    # c("circle", "square", "ellipse", "number", "shade", "color", "pie")
    mar= c(0,0,4,0),
    col= col1(20),	
    main= "Pairwise Correlation")

dev.off()
