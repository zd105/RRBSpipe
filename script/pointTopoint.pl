#!/usr/bin/perl -w
use strict;
die "Usage: perl file1 file2 > out_file\n" unless @ARGV == 2;

my %geneList;
open IN, $ARGV[0];
#chr1    refSeq  mRNA    6407435 6443590 .       6443171 6444542
while (<IN>) {
	chomp;
	my @info = split /\t/;
	my $key = "$info[0]\t$info[1]\t$info[2]"; 
	#$geneList{$key}="$info[1]\t$info[2]\t$info[3]";
	$geneList{$key}=join "\t", @info[3..$#info];
}
close IN;
#chr1    56754   59454   +       ID=NM_001005484; name=OR4F5;    ICPs

open IN, $ARGV[1];
while (<IN>) {
	chomp;
	my @info = split /\t/;
	my $key = "$info[0]\t$info[1]\t$info[2]";
	if(exists $geneList{$key})
	{print join "\t", $_,$geneList{$key},"\n";}
}
close IN;
