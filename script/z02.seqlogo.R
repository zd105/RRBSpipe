args<-commandArgs(TRUE)
if(length(args) != 3){
    stop("seqlogo.R  pwm  [T|F]  pdf
          pwm       :  The W * 4 position frequence matrix:
                       12 12 12 12
                       48  0  0  0
                       0  40  2  6
                       0   0  0 48
                       12 12 12 12
          ic.scale  :  T, the height of each column is proportional to its information content.
                       F, all columns have the same height.
          pdf       :  the output of pdf.")
}
library(seqLogo)
a<-read.table(file=args[1])
a<-t(a)
for( i in 1:ncol(a) ){ a[,i] = a[,i]/sum(a[,i]) }
pdf(file=args[3], width=15)
seqLogo(a,ic.scale=args[2])
dev.off()

######### Introduction for information content #########
#The information content is measured in bits and, in the case of DNA sequences, ranges from 0
#to 2 bits. A position in the motif at which all nucleotides occur with equal probability has an
#information content of 0 bits, while a position at which only a single nucleotide can occur has
#an information content of 2 bits. The information content at a given position can therefore be
#thought of as giving a measure of the tolerance for substitutions in that position: Positions
#that are highly conserved and thus have a low tolerance for substitutions correspond to high
#information content, while positions with a high tolerance for substitutions correspond to
#low information content.
