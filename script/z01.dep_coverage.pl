#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin $Script); #将本程序的目录保存在$Bin
use File::Basename qw(basename dirname);
use Cwd;
use PerlIO::gzip;

my $usage=<<"USAGE";
  
   name: dep_coverage.v1.0.pl
	It is designed for:
	   1. plot Depth-coverage relationship of BS-seq;
	   2. plot >=5x methylation level distribution of BS-seq;
	   3. generate sampleid.coverage_depth.xls (all C sites used)
	   4. generate sampleif.average_methy.xls (>=1xC sites used)
	version:1.0
	usage:   perl $0
			 -i <str>  input cout file, cout.gz is ok; 
			 -o <str>  outdir;
			 -n <str>  samplename;
			 -d <int>  max plot depth,default is 10x;
			 -r <str>  which Rscript use to plot;
			 -h <str>  help;
	author:  zhangdu
	date:    2018-5-27
USAGE

my ($infile,$outdir, $name,$maxplotdepth, $R,$help);
GetOptions("i=s" =>  \$infile,
		   "o=s" => \$outdir,
		   "n=s" => \$name,
		   "d=s" => \$maxplotdepth,
		   "r=s" => \$R,
		   "h=s" => \$help
		   );
die $usage if $help;
die $usage unless $infile;
die $usage unless $outdir;
die $usage unless $name;
$maxplotdepth ||=10;
$R ||="~/src/R-3.4.2/builddir/bin/Rscript";
my %h = ();
my %c = ();
my %m = ();
my %r = ();
my %d = ();
my %dd = ();
my %d5 = ();
my %d10 = ();

open IN, "<:gzip(autopop)", "$infile" || die "Cannot open $infile:$!\n";

while(<IN>){
	chomp;
################cout format############################################
#chr1    3379656 +       CG      GACGG   1.000   2       0       2       0       0       0.342   1.000
#chr1    3379657 -       CG      ACGGT   NA      0       0       0       2       2       NA      NA
#chr1    3379658 -       CHG     CGGTA   NA      0       0       0       2       2       NA      NA
#chr1    3379661 -       CHH     TAGTC   NA      0       0       0       2       2       NA      NA
#############################################################
	my @a = split;
	next if /^#/;
	my $d = $a[6] + $a[7];
	$h{$a[3]}{$d} += 1; # $h{Ctype}{depth}=number
	$c{$a[3]} += 1;# $c{Ctype}=number
	if($d>0){
		$m{$a[3]}{"meth"} += $a[5]; # >=1x的才用来计算甲基化率 $m{Ctype}=totalmethy
		$m{$a[3]}{"numb"} += 1;# $c{Ctype}{"numb"}=number
		$d{$a[3]} += 1;
		$dd{$a[3]} += $d;
	}
	if($d>4){ #only considering >=5 x
		my $win = int( $a[5] / 0.1 ); # 用$win记录该甲基化水平处于哪个窗口：$win=0代表处于[0,0.1);$win=1代表处于[0.1,0.2)
		$r{$a[3]}{$win} += 1; # $r{Ctype}{win}=number
		$d5{$a[3]} += 1; #d5{Ctype}=number
	}
        $d10{$a[3]} += 1 if $d > 9; #only considering >=10 x

}
close IN;

open OA, ">$outdir/$name.accu_cover.xls" or die $!;
print OA "#Depth\tCG\tCHG\tCHH\n";
foreach my $d (1..100){
	my @out = ();
	push @out, $d;
	foreach my $t ("CG", "CHG", "CHH"){
		my $n = 0;
		foreach my $p (keys %{$h{$t}}){
			$n += $h{$t}{$p} if $p >= $d
		}
		push @out,  sprintf("%.8f", $n/$c{$t}); # @out=(depth,CGcoverage,CHGcoverage,CHHcoverage)
	}
	print OA join("\t", @out), "\n";
}
close OA;
system("$R $Bin/z01.accu_cover.R $outdir/$name.accu_cover.xls $outdir/$name.accu_cover.pdf $maxplotdepth");


open OB, ">$outdir/$name.averge_methyl.xls" or die $!;
print OB "Sample\tC\tCG\tCHG\tCHH\n";
my $mean_meth = ($m{"CG"}{"meth"} + $m{"CHG"}{"meth"} + $m{"CHH"}{"meth"}) / ($m{"CG"}{"numb"} + $m{"CHG"}{"numb"} + $m{"CHH"}{"numb"});
print OB join("\t", $name, $mean_meth, $m{"CG"}{"meth"}/$m{"CG"}{"numb"}, $m{"CHG"}{"meth"}/$m{"CHG"}{"numb"}, $m{"CHH"}{"meth"}/$m{"CHH"}{"numb"} ), "\n";
close OB;



open OC, ">$outdir/$name.distribution_methyl.xls" or die $!;
print OC "\tCG\tCHG\tCHH\n";
foreach my $w (0..9){
	my @out = ();
	my $range = $w == 9 ? "[" . $w * 0.1 . "," . ($w+1) * 0.1 . "]" : "[" . $w * 0.1 . "," . ($w+1) * 0.1 . ")";
	push @out, $range;
	foreach my $t ("CG", "CHG", "CHH"){
		my $r = $w == 9 ?  ( $r{$t}{$w} + $r{$t}{ $w + 1 } ) / $d5{$t} : $r{$t}{$w} / $d5{$t};
		push @out, $r;
	}
	print OC join("\t", @out), "\n";
}
close OC;
system("$R $Bin/z01.methyl_distr.R $outdir/$name.distribution_methyl.xls $outdir/$name.distribution_methyl.pdf");


open OD, ">$outdir/$name.coverage_depth.xls" or die $!;
print OD "Sample\ttotal_CG\tmean_depthCG\teffect_depthCG(>=1X)\tcovrageCG\tcoverageCG(d>=5X)\tcoverageCG(d>=10X)\ttotal_CHG\tmean_depthCHG\teffect_depthCHG(>=1X)\tcovrageCHG\tcoverageCHG(d>=5X)\tcoverageCHG(d>=10X)\ttotal_CHH\tmean_depthCHH\teffect_depthCHH(>=1X)\tcovrageCHH\tcoverageCHH(d>=5X)\tcoverageCHH(d>=10X)\n";
print OD join("\t",$name,  $c{"CG"},   $dd{"CG"}/$c{"CG"},   $dd{"CG"}/$d{"CG"},   $d{"CG"}/$c{"CG"},   $d5{"CG"}/$c{"CG"},   $d10{"CG"}/$c{"CG"}, $c{"CHG"}, $dd{"CHG"}/$c{"CHG"}, $dd{"CHG"}/$d{"CHG"}, $d{"CHG"}/$c{"CHG"}, $d5{"CHG"}/$c{"CHG"}, $d10{"CHG"}/$c{"CHG"}, $c{"CHH"}, $dd{"CHH"}/$c{"CHH"}, $dd{"CHH"}/$d{"CHH"}, $d{"CHH"}/$c{"CHH"}, $d5{"CHH"}/$c{"CHH"}, $d10{"CHH"}/$c{"CHH"}, "\n");
close OD;


