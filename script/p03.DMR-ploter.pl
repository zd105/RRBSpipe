#!/usr/bin/perl
use strict;
use warnings;
use PerlIO::gzip;
use Getopt::Long;

my $usage=<<"USAGE";
name:  $0
usage: perl $0
         
       plot methylation levels of different samples or groups for given regions.
         --I   <str>  input file containing DMRs;( or output file of p01.DMR-detector.pl )
                      ### format
                        chr1   1    400   ...
                        chr1   100  500   ...
                        ...
         --E   [int]  Extend <1000> bp for each region. [1000]
         --C   <str>  matrix of CpG methylation (or input file of p01.DMR-detector.pl)
                      ### format;
                        chr   pos    g1     g1     g2     g2
                        chr1  10497  0.950  0.941  0.783  0.930
                        chr1  10499  0.000  0.000  0.000  0.000
                        chr1  10500  0.000  0.000  0.000  0.000
                        ...
         --F   <str>  single sample list or group list you want to plot. 
                      the number means the sample column number(perl colum number, 0 is the firt column) in matrix given -C;
                      ### file format: (one group per line)
                      #name  list 
                        g1     2,3
                        g2     4,5
         --R   [str]  reference.fa, which will be used to calculate the CG density.
         --G   [str]  bed format file containing genic elements you want to plot;The 3th colum is the gene name; 
                      #format
                        chr1   1      100    DDX11L1  id  +
                        chr5   29370  30000  WASH7P   id  -
         --O   [str]  dir of output
         --Rscript [str] Rscript program;
author:  luhanlin
date:
USAGE

my $file_dmr;
my $file_matrix;
my $file_format;
my $file_fasta;
my $file_gene; 
my $dir_output;
my $extend;
my $Rscript;
my $help;

GetOptions (
    "I=s"  => \$file_dmr,
    "C=s"  => \$file_matrix,
    "F=s"  => \$file_format,
    "R:s"  => \$file_fasta,
    "E:i"  => \$extend,
    "G:s"  => \$file_gene,
    "O:s"  => \$dir_output,
	"Rscript:s"  => \$Rscript,
    "help|?|h" => \$help,
);

unless( $file_dmr && $file_matrix && $file_format){
    print $usage;
    exit 1;
}
if($help){
    print $usage;
    exit 0;
}
die $usage unless $Rscript;

### parameters 
$extend ||= 1000;
$dir_output ||= ".";
mkdir $dir_output unless -d $dir_output;

### read fasta file
print STDERR "|-- read fasta file: $file_fasta ..\n";
open FA, $file_fasta or die $!;
my %fa;
my $ch;
while (<FA>) {
    chomp;
    if (/>(\S+)/){
        $ch = $1;
    }
    else{
        $fa{$ch} .= $_;
    }
}
close FA;
print STDERR " --| read fasta file is done ..\n";

### read DMR regions
print STDERR "|-- loading the dmr regions: $file_dmr ..\n";
my %pos2reg;
my %region;
open DMR, $file_dmr or die $!;
while(<DMR>){
    chomp;
	next if(/^#/);
    my @arr = split;
    my ($chr, $st, $ed) = @arr[0..2];
    my $n = sprintf("%06d", $.-1);
    my $id = "RG$n";
    my $ext_st = $st - $extend > 0 ? $st - $extend : 1;
    my $ext_ed = $ed + $extend;
    my $cpg = cpg(\%fa, $chr, $ext_st, $ext_ed); 
    $region{$id}{"chr"} = $chr;
    $region{$id}{"st"} = $st;
    $region{$id}{"exst"} = $ext_st;
    $region{$id}{"ed"} = $ed;
    $region{$id}{"exed"} = $ext_ed;
    $region{$id}{"cpg"} = $cpg;
    foreach my $i ($ext_st..$ext_ed){
	my $pos = "$chr\t$i";
	$pos2reg{$pos}{$id} = 1;
    }
}
close DMR;
print STDERR " --| loading dmr regions is done ..\n";

### read format file
print STDERR "|-- loading the format list: $file_format ..\n";
my %g;
open IN, $file_format or die $!;
while(<IN>){
	chomp;
	my @arr = split;
	my $id = $arr[0];
	my $l = $arr[1];
	my @list = split(/,/, $l);
	push @{$g{$id}}, @list;
}
close IN;
print STDERR " --| loading the format list is done ..\n";

### read the matrix file
print STDERR "|-- loading methyl matrix: $file_matrix ..\n";
my %dat;
if($file_matrix=~/\.gz/){
    open MAT, "<:gzip", $file_matrix or die $!;
}
else{
    open MAT, $file_matrix or die $!;
}
while(<MAT>){
	next if $.==1;
        chomp;
        my @a = split;
	my ($chr, $s) = ($a[0], $a[1]);
	my $pos = "$chr\t$s";
	if ( exists $pos2reg{$pos} ){
		foreach my $id (keys %{$pos2reg{$pos}}){
			foreach my $gp (keys %g){
                        	my @b = @{$g{$gp}};
                                foreach my $lev (@a[@b]){
				      $dat{$id}{$gp}{$pos} .= "$pos\t$lev\n";
				}
			}
		}
	}
}
close MAT;
print STDERR " --| loading methyl matrix is done ..\n";    

### read the gene structure file
print STDERR "|-- loading gene structure: $file_gene ..\n";
my %gene;
open BED, $file_gene or die $!;
while(<BED>){
	chomp;
	my @arr = split;
	my ($chr, $st, $ed, $id, $strand) = @arr[0,1,2,4,5];
	foreach my $i ($st..$ed){
		my $pos = "$chr\t$i";
		if(exists $pos2reg{$pos} ){
			foreach my $id (keys %{$pos2reg{$pos}}){
				my $ge = join("\t", @arr[0,1,2,4,5]);
				$gene{$id}{$ge} = 1;
			}
		}
	}
}
close BED;
print STDERR " --| loading gene structure is done ..\n";
    

print STDERR "|-- start to plot ..\n";
foreach my $id (sort keys %region){
	my $chr = $region{$id}{"chr"};
	my $st = $region{$id}{"st"};
        my $ed = $region{$id}{"ed"};
	my $ext_st = $region{$id}{"exst"};
	my $ext_ed = $region{$id}{"exed"};

        my $cpgfile = "$dir_output/$id.cpgs.txt";
		print $cpgfile."\n";
	open OA, ">$cpgfile" or die $!;
	print OA $region{$id}{"cpg"};
	close OA;

	my $genfile = "$dir_output/$id.gene.txt";
	open OB, ">$genfile" or die $!;
	print OB "$chr\t-1\t-1\tNA\t+\n";
	foreach my $gene (keys %{$gene{$id}}){
		print OB "$gene\n";
	}
	close OB;
        
	my @levfiles = ();	
	my @gpname = ();
        foreach my $gp (keys %{$dat{$id}}){
		my $levfile = "$dir_output/$id.level.$gp.txt";
		open OC, ">$levfile" or die $!;
		foreach my $pos (keys %{$dat{$id}{$gp}}){
			print OC $dat{$id}{$gp}{$pos};
		}
		close OC;
		push @levfiles, $levfile;
		push @gpname, $gp;
	}
        
        plot($chr, $id, $st, $ed, $ext_st, $ext_ed, $cpgfile, $genfile, \@levfiles, \@gpname, $dir_output);
        # system("rm -f $dir_output/$id.*.txt");

}
print STDERR " --| plotting is done ..\n\n\n";


######### sub function

sub cpg{
	my ($h, $chr, $st, $ed) = @_;
	my $seq = substr($$h{$chr}, $st-1, $ed-$st+1);
	my $out = ();
	while($seq =~m/cg/ig){
        	my $base = $1;
        	my $pos = pos($seq) + $st;
		$out .= "$chr\t$pos\t1\n";
                $pos = $pos + 1;
		$out .= "$chr\t$pos\t1\n";
	}
	return $out;
}


########### sub function

sub plot{
    my ($chr, $id, $st, $ed, $ext_st, $ext_ed, $cgf, $genf, $levfs, $names, $dir) = @_;
    my $args = join(" ", $cgf, $genf, @$levfs);
    my $legendname = join("\",\"", @$names);
    $legendname = '"' . $legendname . '"';
    my $c = @$names + 2;
    my $Rline=<<"RL";
#########################
args <- commandArgs(TRUE)
cgf   <- read.table(args[1])
tssf  <- read.table(args[2])

start <- $ext_st
end   <- $ext_ed
dmr_s <- $st
dmr_e <- $ed


scol <- c( rgb(0,0,0,1),         rgb(1,1,1,1),
  rgb(189/255,28/255,44/255,1),  rgb(32/255,60/255,153/255,1), 
  rgb(236/255,99/255,34/255,1),  rgb(11/255,161/255,75/255,1), 
  rgb(127/255,62/255,152/255,1), rgb(252/255,220/255,21/255,1))

pcol <- c( rgb(0,0,0,0.7),         rgb(1,1,1,0.7),
  rgb(189/255,28/255,44/255,0.7),  rgb(32/255,60/255,153/255,0.7), 
  rgb(236/255,99/255,34/255,0.7),  rgb(11/255,161/255,75/255,0.7), 
  rgb(127/255,62/255,152/255,0.7), rgb(252/255,220/255,21/255,0.7))

########
# plot #
########
pdf( file="$dir/$id.plot.pdf", width=12, height=8)

nf<-layout(matrix(c(1,2,3), ,1,byrow=TRUE), c(2800), c(250,900,350), TRUE)
#layout.show(nf)

######## 1 func
sline <- function(Ma){
    a <- subset(Ma,!is.na(Ma[,2]))
    a <- a[order(a[,1]),]
    c <- unique(a[,1])
    c <- cbind(c,0)
    for(k in 1:nrow(c)){
        c[k,2] <- mean( a[which(a[,1]==c[k,1]),2] )
    }
    a <- c
    r <- nrow(a)
    b <- matrix(rep(0,(a[r,1]-a[1,1]+1)*2), , 2, byrow=TRUE)
    num <- 1
    b[num,1] <- a[1,1]
    b[num,2] <- a[1,2]
    for( i in 1:(nrow(a)-1) ){
        for (j in (a[i,1]+1):a[i+1,1]){
            num <- num + 1;
            b[num,1] <- j
            if(j==a[i+1,1]){
                b[num,2]<-a[i+1,2]
            }
            else{
                if(a[i+1,1]==a[i,1]){
                    b[num,2] <- a[i,1]
                }
                else{
                    b[num,2] <- a[i,2] + ( (a[i+1,2]-a[i,2]) * (j-a[i,1]) / (a[i+1,1]-a[i,1]))
                }
            }
        }
    }
    b
}


######## 2. gene structure
par(mar=c(0,7,4,1), las=1, cex.lab=1.5, cex.axis=1.5)
plot(0, 
  type="n", 
  ylim=c(-0.5,1), 
  xlim=c(start, end),
  col=1, 
  xaxt="n",
  yaxt="n", 
  bty="o", 
  xlab="", 
  ylab="")
mtext("$chr", side=2, cex=1.5, line=2)
segments(start, 0.4, end, 0.4, col=1)
for (k in 1:nrow(tssf)){
    text(tssf[k,3], 0, tssf[k,4])
    if(tssf[k,5] == "+"){
        rect(tssf[k,2], 0.2, 0.05*(end-start)+tssf[k,2], 0.6, col=rgb(0,0,0,0.5), border=NA)
        segments(tssf[k,2], 0.2, tssf[k,2], 0.8, col=1, lwd=1)
        arrows(tssf[k,2], 0.8, 0.07*(end-start)+tssf[k,2], 0.8, angle=15, code=2, length=0.2, lwd=1, col="red")
    }else{
        rect(tssf[k,3], 0.2, tssf[k,3]-(0.05*(end-start)), 0.6, col=rgb(0,0,0,0.5), border=NA)
        segments(tssf[k,3], 0.2, tssf[k,3], 0.8, col=1, lwd=1)
        arrows(tssf[k,3], 0.8, tssf[k,3]-(0.07*(end-start)), 0.8, angle=15, code=2, length=0.2, lwd=1, col="red")
    }
}


######## 3. plot methy
par(mar=c(0,7,0,1),las=1,cex.lab=2, cex.axis=1.5)
plot(0, 
  type="n", 
  xlim=c(start, end), 
  xaxt="n",
  ylim=c(0,1), 
  ylab="CG\nMethyl Level")

legend("topleft", 
    legend=c($legendname), 
    col=scol[3:$c], 
    pch=19, 
    bty="n", 
    cex=1.5)


for (i in 3:length(args)){
  dat <- read.table(args[i])
  points(dat[,2], dat[,3], pch=20, cex=1, col=pcol[i])
  la <- as.matrix(cbind(dat[,2],dat[,3]))
  la <- sline(la)
  a <- smooth.spline(la[,2], df=25)
  points(a\$x+la[1,1]-1, a\$y, type="l", col=pcol[i], lwd=2)
}

#abline(h=0, lwd=2)
rect(dmr_s, 0, dmr_e, 1, col=rgb(255/255,255/255,0,0.3), border=NA)

######## 4. GCdensity
par(mar=c(5,7,0,1), las=1, cex.lab=2, cex.axis=1.5)
plot(0,
   type="n", 
   xlim=c(start, end),
   ylim=c(-0.05,1),
   ylab="CG\ndensity", 
   xlab="")
#axis(2,at=c(-15,0,15),lab=c(15,0,15))
#abline(h=0)
points(cgf[,2], rep(-0.05,nrow(cgf)), col=rgb(0.48,0.48,0.48,0.5), type="h", lwd=1, lend=2)

par(new=T,mar=c(5,7,0,1))
a <- density(cgf[,2], width=100)
plot(a\$x,a\$y, type="l", lwd=1, xlab="", ylab="", xaxt="n", yaxt="n")
########
dev.off()
######## 

RL
    open RL, ">$dir/$id.plot.R" or die $!;
    print RL $Rline;
    close RL;
    system("$Rscript $dir/$id.plot.R $args");
}
###
