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
die "Usage: perl $0 1.fq 2.fq out.fq \n" unless @ARGV==3;
my ($pe1, $pe2, $out) = @ARGV;
######
if ($pe1=~/\.gz$/){
    open IA,"<:gzip","$pe1" or die "$! --> $pe1\n";
}
else{
    open IA,"<$pe1" or die "$! --> $pe1\n";
}
######
if ($pe2=~/\.gz$/){
    open IB,"<:gzip","$pe2" or die "$! --> $pe2\n";
}
else{
    open IB,"<$pe2" or die "$! --> $pe2\n";
}
######
if ($out=~/\.gz$/){
    open OUT, ">:gzip", "$out" or die $!;
}
else{
    open OUT, ">$out" or die $!;
}
##########
my $tt = 0;
my $rr = 0;
while(my $a1 = <IA>){
    $rr ++;
    my $a2 = <IA>;
    my $a3 = <IA>;
    my $a4 = <IA>;
    my $b1 = <IB>;
    my $b2 = <IB>;
    my $b3 = <IB>;
    my $b4 = <IB>;
    my $id1 = substr($a1, 2, 9);
    my $id2 = substr($b1, 2, 9);
    $tt ++ if $id1 eq $id2;
    print OUT $a1.$a2.$a3.$a4;
    print OUT $b1.$b2.$b3.$b4;
}
print STDERR "Total $rr reads in PE1..\nTotal $tt pairs of reads..\n";
close IA;
close IB;
close OUT;
