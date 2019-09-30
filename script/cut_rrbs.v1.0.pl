#!/usr/bin/perl 
use strict;
use warnings;
use Getopt::Long;
use PerlIO::gzip;
my $usage=<<"USAGE";
name:    $0
usage:   perl $0
         This perl is for RRBS, For sigle emzyme digest RRBS,it will cut the TGA in read1 3', and cut CA in read2 5';
         For double emzyme digest RRBS,it will cut the TGA or TGWA in read1 3', and cut CA or CWA in read2 5'.
            -i  <str>   in fq[.gz] file;
            -o  [str]   out fq.gz file;
            -m  <int>   mode,0 for RRBS(defualt);1 for DRRBS;
            -h  <str>   help
author:  zhangdu
e-mail:  zhangducsu\@163.com
date: 2018-10-10
version: 1.0
USAGE
my ($fq,$out,$mode,$help);
GetOptions (
		"i=s"        => \$fq,
		"o=s"     => \$out,
		"m=i"     => \$mode,
		"h=s"          => \$help
		);

die $usage if $help;
die $usage unless $fq;
die $usage unless $out;
$mode ||= 0;
my $time=`date`;

my $enzyme = 0;
my $total = 0;
my $cut3 = 0;
my $cut5 = 0;
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
if($mode ==0){
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
				$cut3 +=1;
			}
		}else{
			if( $line2=~/^CA/){
				$line2=~s/^CA//;
				$line4=~s/^\S{2}//;
				$cut5 +=1;
			}
		}
		print OUT "$line1\n$line2\n$line3\n$line4\n";
	}

	print STDERR "Total     reads   pairs -> $total\n";
	print STDERR "Enzymed   reads   pairs -> $enzyme\n";
	print STDERR "Total cut 3'TG in read1 -> $cut3\n";
	print STDERR "Total cut 5'CA in read2 -> $cut5\n";
####
}else{
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
			$enzyme += 1 if($line2=~/^[NTC]GG/ || $line2=~/^[NTC]TG[NTC]/ || $line2=~/^[NTC]AG[NTC]/);
			if( $line2=~/TG[AN]$/){
				$line2=~s/TG[AN]$//;
				$line4=~s/\S{3}$//;
				$cut3 +=1;
			}elsif( $line2=~/TAG[AN]$/){
				$line2=~s/TAG[AN]$//;
				$line4=~s/\S{4}$//;
				$cut3 +=1;
			}elsif( $line2=~/TTG[AN]$/){
				$line2=~s/TTG[AN]$//;
				$line4=~s/\S{4}$//;
				$cut3 +=1;
			}
		}else{
			if( $line2=~/^CA/){
				$line2=~s/^CA//;
				$line4=~s/^\S{2}//;
				$cut5 +=1;
			}elsif( $line2=~/^CAA/){
				$line2=~s/^CAA//;
				$line4=~s/^\S{3}//;
				$cut5 +=1;
			}elsif( $line2=~/^CTA/){
				$line2=~s/^CTA//;
				$line4=~s/^\S{3}//;
				$cut5 +=1;
			}
		}
		print OUT "$line1\n$line2\n$line3\n$line4\n";
	}
	print STDERR "Total     reads   pairs -> $total\n";
	print STDERR "Enzymed   reads   pairs -> $enzyme\n";
	print STDERR "Total cut 3'TG/TWG in read1 -> $cut3\n";
	print STDERR "Total cut 5'CA/CWA in read2 -> $cut5\n";

}
close IN;
close OUT;





