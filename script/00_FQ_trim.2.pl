#!/usr/bin/perl 
#===============================================================================
#         FILE:  fastq_clean.pl
#        USAGE:  perl fastq_clean.pl
#  DESCRIPTION:
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  luhanlin@genomics.org.cn
#      COMPANY:  BGI
#      VERSION:  1.0
#      CREATED:  05/06/2010 05:17:07 PM
#===============================================================================
use strict;
use warnings;
use PerlIO::gzip;
die "Usage: perl $0 in.fq [1|2] out.fq \n" unless @ARGV==3;
my ($fq, $pe, $out) = @ARGV;
if ($fq=~/\.gz$/){
    open IN,"zcat $fq |" or die "$! --> $fq\n";
}
else{
    open IN,"<$fq" or die "$! --> $fq\n";
}
if ($out=~/\.gz$/){
    open OUT, ">:gzip", "$out" or die $!;
}
else{
    open OUT, ">$out" or die $!;
}
##########
my $tt = 0;
while(my $line1 = <IN>){
    $tt += 1;
    my $num = sprintf("%09d",$tt);
    $line1 = "\@R$num:$pe\n";
    my $line2 = <IN>;
    my $line3 = <IN>;
    my $line4 = <IN>;
    print OUT $line1.$line2."+\n".$line4;
}
close IN;
close OUT;
