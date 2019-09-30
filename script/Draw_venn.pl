#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
use Cwd;
use PerlIO::gzip;
#~~~~~~~~      USAGE      ~~~~~~~~#
my $usage=<<"USAGE";
name:    $0
usage:   perl $0
              -I <>   list1
                  or list1,list2
                  or list1,list2,list3
                  or list1,list2,list3,list4
                  or list1,list2,list3,list4,list5
                  list[1..5] is a input file containing one column (e.g., integers, chars),
                   with each component corresponding to a separate circle in the Venn diagram
              -N []  name1,name2,..name5
              -Rscript [] Rscript program 
              -O []  out.pdf
author:  luhanlin\@genomics.org.cn
date:
USAGE
#~~~~~~~~  Globle Parameters  ~~~~~~~~#
my ($filelist, $namelist, $pdf, $help,$Rscript);
GetOptions(
    "help|?|h" => \$help,
    "I=s"      => \$filelist,
    "N:s"      => \$namelist,
    "Rscript:s"      => \$Rscript,
    "O:s"      => \$pdf,
);
die $usage if $help;
die $usage unless ($filelist);
die $usage unless $Rscript;
my (@flist, @nlist);
my ($readtable, $make_list, $p, $Rcode);
my @lab = qw(A B C D E);

$pdf ||= "Venn.pdf";

if ($pdf=~/(\S+)\.pdf$/){
    $p = $1;
}
else{
    $p = $pdf;
}
#~~~~~~~~~   Main Process     ~~~~~~~~#

@flist = split(/,/, $filelist);

die "\nNumber of filelist must <= 5 && >=1\n\n$usage" if (@flist>5 || @flist<1);

foreach (@flist){
    if(!-e $_){
        die "$_ : can not find it, please check it!\n$usage";
    }
}

if (defined $namelist){
    @nlist = split(/,/, $namelist);
    die "# of namelist != # of filelist\n" unless $#nlist == $#flist;
}
else{
    for (my $i=0; $i<=$#flist; $i++){
        push @nlist, $lab[$i];
    }
}

foreach (my $i=0; $i<@flist; $i++){
    $readtable .= "$lab[$i]<-read.table(\"$flist[$i]\")\n";
    $make_list .= " \"$nlist[$i]\"=as.vector($lab[$i]"."[,1]),";
}
$make_list=~s/,$//;
$make_list = 'x=list(' . $make_list . '),';
$Rcode = $readtable;

if(@flist==1){
    $Rcode .= "Venn( $make_list filename = \"$p.pdf\", col = \"black\", lwd = 8, fontface = \"bold\", fill = \"grey\", alpha = 0.75, cex = 4, cat.cex = 3, cat.fontface = \"bold\", margin = 0.1 );\n";
}
elsif(@flist==2){
    $Rcode .= "Venn( $make_list filename = \"$p.pdf\", lwd = 4, fill = c(\"cornflowerblue\", \"darkorchid1\"), alpha = 0.75, label.col = \"black\", cex = 3, fontfamily = \"serif\", fontface = \"bold\", cat.col = c(\"cornflowerblue\", \"darkorchid1\"), cat.cex = 2, cat.fontfamily = \"serif\", cat.fontface = \"bold\", cat.dist = c(0.03, 0.03), cat.pos = c(-20, 14), margin = 0.05 );\n";
}
elsif(@flist==3){
    $Rcode .= "Venn( $make_list filename = \"$p.pdf\", col = \"black\", lwd = 4, fill = c(\"red\", \"blue\", \"green\"), alpha = 0.5, label.col = c(\"darkred\", \"white\", \"darkblue\", \"white\", \"white\", \"white\", \"darkgreen\"), cex = 2.5, fontfamily = \"serif\", fontface = \"bold\", cat.default.pos = \"text\", cat.col = c(\"darkred\", \"darkblue\", \"darkgreen\"), cat.cex = 2.5, cat.fontfamily = \"serif\", cat.dist = c(0.06, 0.06, 0.03), cat.pos = 0, margin = 0.1 );\n";
}
elsif(@flist==4){
    $Rcode .= "Venn( $make_list filename = \"$p.pdf\", col = \"black\", lwd = 3, fill = c(\"cornflowerblue\", \"green\", \"yellow\", \"darkorchid1\"), alpha = 0.50, label.col = c(\"orange\", \"white\", \"darkorchid4\", \"white\", \"white\", \"white\", \"white\", \"white\", \"darkblue\", \"white\", \"white\" , \"white\", \"white\", \"darkgreen\", \"white\"), cex = 1.5, fontfamily = \"serif\", fontface = \"bold\", cat.col = c(\"darkblue\", \"darkgreen\", \"orange\", \"darkorchid4\"), cat.cex = 1.5, cat.pos = 0, cat.dist = 0.07, cat.fontfamily = \"serif\", rotation.degree = 0, margin = 0.1  );\n";
}
elsif(@flist==5){
    $Rcode .= "Venn( $make_list filename = \"$p.pdf\", col = \"black\", fill = c(\"dodgerblue\", \"goldenrod1\", \"darkorange1\", \"seagreen3\", \"orchid3\"), alpha = 0.50, cex = c(1.5, 1.5, 1.5, 1.5, 1.5, 1, 0.8, 1, 0.8, 1, 0.8, 1, 0.8, 1, 0.8, 1, 0.55, 1, 0.55, 1, 0.55, 1, 0.55, 1, 0.55, 1, 1, 1, 1, 1, 1.5), cat.col = c(\"dodgerblue\", \"goldenrod1\", \"darkorange1\", \"seagreen3\", \"orchid3\"), cat.cex = 1.5, cat.fontface = \"bold\", margin = 0.05  );\n";
}

$Rcode = Rfunc().$Rcode;
open R,">$p.R" or die "$p.R  : $!";
print R $Rcode;
close R;
system ("$Rscript $p.R");

sub Rfunc{
    my $Rfunc=<<Rline;
library(VennDiagram)
## function
Venn<-function (x, filename, height = 5, width = 5, na = "stop", main = NULL,
    sub = NULL, main.pos = c(0.5, 1.05), main.fontface = "plain",
    main.fontfamily = "serif", main.col = "black", main.cex = 1,
    main.just = c(0.5, 1), sub.pos = c(0.5, 1.05), sub.fontface = "plain",
    sub.fontfamily = "serif", sub.col = "black", sub.cex = 1,
    sub.just = c(0.5, 1), category.names = names(x), force.unique = TRUE,
    ...)
{
    if (force.unique) {
        for (i in 1:length(x)) {
            x[[i]] <- unique(x[[i]])
        }
    }
    if ("none" == na) {
        x <- x
    }
    else if ("stop" == na) {
        for (i in 1:length(x)) {
            if (any(is.na(x[[i]]))) {
                stop("NAs in dataset", call. = FALSE)
            }
        }
    }
    else if ("remove" == na) {
        for (i in 1:length(x)) {
            x[[i]] <- x[[i]][!is.na(x[[i]])]
        }
    }
    else {
        stop("Invalid na option: valid options are \\"none\\", \\"stop\\", and \\"remove\\"")
    }
    if (0 == length(x) | length(x) > 5) {
        stop("Incorrect number of elements.", call. = FALSE)
    }
    if (1 == length(x)) {
        list.names <- category.names
        if (is.null(list.names)) {
            list.names <- ""
        }
        grob.list <- VennDiagram::draw.single.venn(area = length(x[[1]]),
            category = list.names, ind = FALSE, ...)
    }
    else if (2 == length(x)) {
        grob.list <- VennDiagram::draw.pairwise.venn(area1 = length(x[[1]]),
            area2 = length(x[[2]]), cross.area = length(intersect(x[[1]],
                x[[2]])), category = category.names, ind = FALSE,
            ...)
    }
    else if (3 == length(x)) {
        A <- x[[1]]
        B <- x[[2]]
        C <- x[[3]]
        list.names <- category.names
        nab <- intersect(A, B)
        nbc <- intersect(B, C)
        nac <- intersect(A, C)
        nabc <- intersect(nab, C)
        grob.list <- VennDiagram::draw.triple.venn(area1 = length(A),
            area2 = length(B), area3 = length(C), n12 = length(nab),
            n23 = length(nbc), n13 = length(nac), n123 = length(nabc),
            category = list.names, ind = FALSE, list.order = 1:3,
            ...)
    }
    else if (4 == length(x)) {
        A <- x[[1]]
        B <- x[[2]]
        C <- x[[3]]
        D <- x[[4]]
        list.names <- category.names
        n12 <- intersect(A, B)
        n13 <- intersect(A, C)
        n14 <- intersect(A, D)
        n23 <- intersect(B, C)
        n24 <- intersect(B, D)
        n34 <- intersect(C, D)
        n123 <- intersect(n12, C)
        n124 <- intersect(n12, D)
        n134 <- intersect(n13, D)
        n234 <- intersect(n23, D)
        n1234 <- intersect(n123, D)
        grob.list <- VennDiagram::draw.quad.venn(area1 = length(A),
            area2 = length(B), area3 = length(C), area4 = length(D),
            n12 = length(n12), n13 = length(n13), n14 = length(n14),
            n23 = length(n23), n24 = length(n24), n34 = length(n34),
            n123 = length(n123), n124 = length(n124), n134 = length(n134),
            n234 = length(n234), n1234 = length(n1234), category = list.names,
            ind = FALSE, ...)
    }
    else if (5 == length(x)) {
        A <- x[[1]]
        B <- x[[2]]
        C <- x[[3]]
        D <- x[[4]]
        E <- x[[5]]
        list.names <- category.names
        n12 <- intersect(A, B)
        n13 <- intersect(A, C)
        n14 <- intersect(A, D)
        n15 <- intersect(A, E)
        n23 <- intersect(B, C)
        n24 <- intersect(B, D)
        n25 <- intersect(B, E)
        n34 <- intersect(C, D)
        n35 <- intersect(C, E)
        n45 <- intersect(D, E)
        n123 <- intersect(n12, C)
        n124 <- intersect(n12, D)
        n125 <- intersect(n12, E)
        n134 <- intersect(n13, D)
        n135 <- intersect(n13, E)
        n145 <- intersect(n14, E)
        n234 <- intersect(n23, D)
        n235 <- intersect(n23, E)
        n245 <- intersect(n24, E)
        n345 <- intersect(n34, E)
        n1234 <- intersect(n123, D)
        n1235 <- intersect(n123, E)
        n1245 <- intersect(n124, E)
        n1345 <- intersect(n134, E)
        n2345 <- intersect(n234, E)
        n12345 <- intersect(n1234, E)
        grob.list <- VennDiagram::draw.quintuple.venn(area1 = length(A),
            area2 = length(B), area3 = length(C), area4 = length(D),
            area5 = length(E), n12 = length(n12), n13 = length(n13),
            n14 = length(n14), n15 = length(n15), n23 = length(n23),
            n24 = length(n24), n25 = length(n25), n34 = length(n34),
            n35 = length(n35), n45 = length(n45), n123 = length(n123),
            n124 = length(n124), n125 = length(n125), n134 = length(n134),
            n135 = length(n135), n145 = length(n145), n234 = length(n234),
            n235 = length(n235), n245 = length(n245), n345 = length(n345),
            n1234 = length(n1234), n1235 = length(n1235), n1245 = length(n1245),
            n1345 = length(n1345), n2345 = length(n2345), n12345 = length(n12345),
            category = list.names, ind = FALSE, ...)
    }
    else {
        stop("Invalid size of input object")
    }
    if (!is.null(sub)) {
        grob.list <- add.title(gList = grob.list, x = sub, pos = sub.pos,
            fontface = sub.fontface, fontfamily = sub.fontfamily,
            col = sub.col, cex = sub.cex)
    }
    if (!is.null(main)) {
        grob.list <- add.title(gList = grob.list, x = main, pos = main.pos,
            fontface = main.fontface, fontfamily = main.fontfamily,
            col = main.col, cex = main.cex)
    }
    if (!is.null(filename)) {
        pdf(file = filename, height = height, width = width)
        grid.draw(grob.list)
        dev.off()
        return(1)
    }
    plot.new()
    grid.draw(grob.list)
}\n
Rline
    return($Rfunc);
}
