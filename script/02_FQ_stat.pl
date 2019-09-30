#!/usr/bin/perl
#       AUTHOR:  luhanlin@genomics.org.cn
#      COMPANY:  BGI
#      VERSION:  1.0
#      CREATED:  05/06/2010 05:17:07 PM
use strict;
use warnings;
use PerlIO::gzip;
die "Usage: perl $0 fq_list out.prefix \n" unless @ARGV>=2;

my @file = @ARGV;
my $stat = pop( @file );
my $reads;
my $base;
my $q20;
my $q30;
my $Q = 33;

print STDERR "Begin..\n";
foreach my $fq (@file){
    my $in;
    print STDERR "Read $fq..\n";
    if ($fq=~/\.gz$/){
        open $in, "<:gzip","$fq" or die "$! --> $fq\n";
    }else{
        open $in, "<$fq" or die "$! --> $fq\n";
    }
    while(<$in>){
        $reads += 1;
        my $seq = <$in>;
        chomp $seq;
        $base += length($seq);
        <$in>;
        my $qual = <$in>; chomp $qual;
	foreach ( split(//,$qual) ){
		$q20 += 1 if ord($_) - $Q >= 20;
		$q30 += 1 if ord($_) - $Q >= 30;
	}
    }
    close $in;
}

open OUT, ">$stat", or die $!;
print OUT "Reads\tBase\tQ20\tQ20_r\tQ30\tQ30_r\n";
print OUT join("\t",$reads, $base, $q20, sprintf("%.6f", $q20/$base), $q30, sprintf("%.6f", $q30/$base), ) . "\n";
close OUT;
print STDERR "Done..\n";
##########

