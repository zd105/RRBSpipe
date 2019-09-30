#!/usr/bin/perl 
#===============================================================================
#         FILE:  fastq_clean.pl
#        USAGE:  
#  DESCRIPTION:  This perl is for RRBS, so it will cut the TGA in read1 3', and cut CA in read2 5'
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
die "Usage: perl $0 in.fq out.fq \n" unless @ARGV==2;
my ($fq, $out) = @ARGV;
my $enzyme = 0;
my $total = 0;
if ($fq=~/\.gz$/){
    open IN,"<:gzip","$fq" or die "$! --> $fq\n";
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
while(my $line1 = <IN>){
    chomp($line1);
    my $line2 = <IN>;
    chomp $line2;
    my $line3 = <IN>;
    chomp $line3;	
    my $line4 = <IN>;
    chomp $line4;
    if($line1=~/:1$/){
	$total += 1;
	$enzyme += 1 if $line2=~/^[NTC]GG/;
	if( $line2=~/TG[AN]$/){
	    $line2=~s/TG[AN]$//;
	    $line4=~s/\S{3}$//;
	}
    }else{
	if( $line2=~/^CA/){
	    $line2=~s/^CA//;
	    $line4=~s/^\S{2}//;
	}
    }
    print OUT "$line1\n$line2\n$line3\n$line4\n";
}
close IN;
close OUT;

print STDERR "Total    reads  pairs -> $total\n";
print STDERR "Enzymed  reads  pairs -> $enzyme\n";

####
