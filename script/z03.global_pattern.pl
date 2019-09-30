#!/usr/bin/perl  
use strict;
use warnings;
use PerlIO::gzip;
use Getopt::Long;
use FindBin qw($Bin $Script);

my $usage=<<"USAGE";
name:    $0
usage:   perl $0
        -I   <str>  file     input *.cout 
		-N   <str>  name     chr name
		-B   <int>  number   the statistics  window (bp), default 10000;
		-O   [str]  dir      output dir of file
		-R   [str]  prom     path of Rscript 
author:  luhanlin\@genomics.org.cn
date:
USAGE

my ($help, $cout, $bin,$name, $outdir, $Rscript);

GetOptions(
    "H|help|?" => \$help,
    "I=s" => \$cout,
    "N:s" => \$name,
	"B=i" => \$bin,
    "O:s" => \$outdir,
    "R:s" => \$Rscript,
);

$name ||= "test";
$outdir ||= ".";
$Rscript ||= "/public/home/zhangdu/src/R-3.4.2/builddir/bin/Rscript";
$bin ||=10000;

if($help){
    print $usage;
    exit 0;
}

unless($cout){
    print $usage;
    exit 1;
}

if($cout=~/\.gz$/){
        open IN, "<:gzip", $cout or die $!;
}
else{
        open IN, $cout or die $!;
}

my %n;
my %m;
my %cg_content;

while(<IN>){
	next if /^#/;
	chomp;
	my @a = split(/\t/, $_);
	next unless $a[0] eq $name;
	my $d += $a[6] + $a[7];
	my $win = int( $a[1] / $bin );# 常用来确定对数据进行窗口化分的方法
	$n{$win}{$a[3]}{$a[2]} += $d; #窗口内测到的CG总次数
	$m{$win}{$a[3]}{$a[2]} += $a[6];#窗口内测到mCG的总次数
        $cg_content{$win} += 1; #窗口内的CG总数
}
close IN;

open OA, ">$outdir/$name.global_pattern.xls" or die $!;
print OA "##bins\tcg_content\tcg+\tchg+\tchh+\tcg-\tchg-\tchh-\n";
foreach my $win (sort{$a<=>$b} keys %n){
	
	my $cgcont = $cg_content{$win} ? sprintf("%.6f", $cg_content{$win} / $bin) : 0; #CG含量：CG总数/窗口长度
	
	my $cg_p  = $n{$win}{"CG"}{"+"}  ? sprintf("%.6f", $m{$win}{"CG"}{"+"}  / $n{$win}{"CG"}{"+"})  : 0; #窗口内正链CG甲基化水平
	my $chg_p = $n{$win}{"CHG"}{"+"} ? sprintf("%.6f", $m{$win}{"CHG"}{"+"} / $n{$win}{"CHG"}{"+"}) : 0; 
	my $chh_p = $n{$win}{"CHH"}{"+"} ? sprintf("%.6f", $m{$win}{"CHH"}{"+"} / $n{$win}{"CHH"}{"+"}) : 0;
	
	my $cg_n  = $n{$win}{"CG"}{"-"}  ? sprintf("%.6f", $m{$win}{"CG"}{"-"}  / $n{$win}{"CG"}{"-"})  : 0;#窗口内负链CG甲基化水平
	my $chg_n = $n{$win}{"CHG"}{"-"} ? sprintf("%.6f", $m{$win}{"CHG"}{"-"} / $n{$win}{"CHG"}{"-"}) : 0;
	my $chh_n = $n{$win}{"CHH"}{"-"} ? sprintf("%.6f", $m{$win}{"CHH"}{"-"} / $n{$win}{"CHH"}{"-"}) : 0;
	print OA join("\t", $win * $bin, $cgcont, $cg_p, $chg_p, $chh_p, $cg_n, $chg_n, $chh_n), "\n";
}
close OA;

system("$Rscript $Bin/z03.global_pattern.R $outdir/$name.global_pattern.xls $name $outdir/$name.global_pattern.pdf");
##
