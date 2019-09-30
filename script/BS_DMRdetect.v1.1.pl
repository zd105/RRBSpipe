#!/usr/bin/perl
use strict;
use Getopt::Long;
use FindBin qw($Bin);
#use Math::Combinatorics;
use Cwd 'abs_path';
my $usage=<<"USAGE";
  
 name:    rrbs_DMRdetect
            
            It is designed for detect DMR among groups of  BS-seq.
 version:1.1
 usage:   perl $0
            -i        <str>  map file; 
            -bedgraph <str>  .bedgraph file dir;
            -o        <str>  results file path;
            -d        <int>  C site cut depth; select as your process in previous steps.
            -t        <str>  C type: CG,CHG or CHH; Default is CG;
            -thread   <int>  Default 4;
            -maxdist  <int>  max C distance to define a DMR; Default is 300;
            -minc     <int>  min mC sites number in  DMR detection; Default is 3;
            -diff     <flt>  min methylation difference in DMR detection;Default is 0.1;
            -X        <int>  minimal number of values in group A (default:-1, means at lest 80% of samples in group A);
            -Y        <int>  minimal number of values in group B (default:-1, means at lest 80% of samples in group B);
            -p        <flt>  use p-value to filtering DMRs in  DMR detection. you should not assign -q if this parameters is assigned ; Default is 0.05;
            -q        <flt>  use q-value to filtering DMRs in  DMR detection; Default is 0.05;
            -pairwise <str>  pairwise group comparison mode list like: "CON-CASE1,CON-CASE2,...";
            -ele      <str>  "global" for genome-wide DMR detection; provide a bed-file for pre-defined regions DMR detection; Default is "global".
            -elename  <str>  region name for pre-defined regions DMR detection in "-ele" parameter;
            -metilene  <str>  metilene program;
            -bedtools <str>  bedtools excutable file;
            -Rscript <str>  Rscript program;
            -h <str>  help;
 author:  zhangdu
 date: 2018-06-20
USAGE

my $p1="$Bin/p01.DMR-detector.v1.2.pl";


my ($file,$outfile,$type,$x,$y,$diff,$bedgraph,$p_value,$q_value,$maxDistance,$mincpg,$thread,$element,$elename,$bedtools,$depth,$pairwise,$Rscript,$metilene);
my $help;
GetOptions("i=s"       =>  \$file,
           "b=s"       => \$bedgraph,
		   "d=i"       => \$depth,
		   "t=s"       => \$type,
		   "thread=i"  => \$thread,
		   "ele=s"     => \$element,
		   "elename=s" => \$elename,
		   "minc=i"    => \$mincpg,
		   "pairwise=s" => \$pairwise,
		   "maxdist=i" => \$maxDistance,
		   "diff=f"    => \$diff,
		   "p=f"       => \$p_value,
		   "q=f"       => \$q_value,
		   "X=i"       => \$x,
		   "Y=i"       => \$y,
		   "metilene=s" => \$metilene,
		   "bedtools=s" => \$bedtools,
		   "Rscript=s"     => \$Rscript,
           "o=s"       => \$outfile,
           "h=s"       => \$help
		   );
die $usage if $help;
die $usage unless $file;
die $usage unless $outfile;
die $usage unless $bedgraph;
die $usage unless $depth;
die $usage unless $pairwise;
die $usage unless $metilene;
die $usage unless $bedtools;
die $usage unless $Rscript;
die $usage if(defined $p_value && defined $q_value);
if(!defined $p_value && !defined $q_value){$q_value = 0.05};
die $usage if(defined $elename && !defined $element);

$thread ||= 4;
$element ||= "global";
$diff ||=0.1;
$mincpg ||= 3;
$maxDistance ||= 300;
$x ||= -1;
$y ||= -1;
$type ||= "CG";

my %groupindex;
my $group;
print "|-----Reading map file...\n";
open FILE, $file or die "can not open $file:$!";     #打开文件   
my $group="$outfile\/$type.sample_group_bedgraph.txt";
open GROUP, ">$group" or die "can not open $group:$!";
  while(<FILE>){   
       chomp $_;
       next if(/^#Group/);
       my @sampleinfo=split(/\t/,$_);
       print $sampleinfo[1]."\n";
	   #$groupindex{$sampleinfo[0]}=$sampleinfo[1];
	   #my $opath="$outfile\/$sampleinfo[1]\/";
	   my $in="$bedgraph\/$sampleinfo[1]\/$sampleinfo[1]\_$depth"."x"."$type\.bedgraph";
	   if(!-e $in){print "INPUT FATAL ERRO: erro depth parameters, please check your input of \"-d\"!!!!!!!\n";die};
	   print GROUP "$sampleinfo[1]\t$sampleinfo[0]\t$in\n";
  }   
close GROUP;
close FILE;

##########Combinatorics
#my @grouparry;
#while(my($key, $value) = each(%groupindex)) {
#	push @grouparry, $key;
#}

#my @tmpitem=split(/\n/,join("\n", map { join ",", @$_ } combine(2,@grouparry)),"\n");
#for(my $i=0;$i<=$#tmpitem;$i++){
#	$groupindex{$tmpitem[$i]}='Y';
#}

my @pairwiselist=split(/\,/,$pairwise);

my $n=0;
my $typedir="$outfile\/m$type\_DMR";
#while(my($key, $value) = each(%groupindex)){
foreach my $cmp(@pairwiselist){
		$n++;
		my @g =split(/\-/,$cmp);
		my $cmpdir="$typedir\/$cmp";
		system("mkdir -p $cmpdir");
		my $subgroup="$cmpdir\/$cmp.$type.compare.map";
		print "=========================================================================\n";
		print "|-----$type DMR detection between groups: $cmp ...\n";
		print "=========================================================================\n";
		system("date");
		system("perl -alne 'print if(\$F[1] eq $g[0] \|\| \$F[1] eq $g[1])' $group > $subgroup");
		if($p_value){
			# use p-value to filter DMR
			if($element eq "global"){
				my $spedir="$cmpdir\/global\-$depth"."x"."\-$mincpg$type\-dist$maxDistance\-D$diff\-P$p_value"; # file name: global-5x-3CG-dist300-D0.1-Q0.05/
				system("mkdir -p $spedir");
				system("perl $p1 -list $subgroup -outdir $spedir -name $cmp -max $maxDistance -min $mincpg -t $thread -f 1 -p $p_value -c $mincpg -r $diff -X $x -Y $y -metilene $metilene -bedtools $bedtools -Rscript $Rscript");
			}else{
				my $spedir="$cmpdir\/$elename\-$depth"."x"."\-$mincpg$type\-dist$maxDistance\-D$diff\-P$p_value";
				system("perl $p1 -list $subgroup -outdir $spedir -name $cmp -max $maxDistance -min $mincpg -t $thread -f 2 -p $p_value -c $mincpg -r $diff -X $x -Y $y -metilene $metilene -bedtools $bedtools -B $element -Rscript $Rscript");
			}

		}elsif($q_value){
			# use q-value to filter DMR
			if($element eq "global"){
				my $spedir="$cmpdir\/global\-$depth"."x"."\-$mincpg$type\-dist$maxDistance\-D$diff\-Q$q_value"; # file name: global-5x-3CG-dist300-D0.1-Q0.05/
				system("mkdir -p $spedir");
				system("perl $p1 -list $subgroup -outdir $spedir -name $cmp -max $maxDistance -min $mincpg -t $thread -f 1 -q $q_value -c $mincpg -r $diff -X $x -Y $y -metilene $metilene -bedtools $bedtools -Rscript $Rscript");
			}else{
				my $spedir="$cmpdir\/$elename\-$depth"."x"."\-$mincpg$type\-dist$maxDistance\-D$diff\-Q$q_value";
				system("perl $p1 -list $subgroup -outdir $spedir -name $cmp -max $maxDistance -min $mincpg -t $thread -f 2 -q $q_value -c $mincpg -r $diff -X $x -Y $y -metilene $metilene -bedtools $bedtools -B $element -Rscript $Rscript");
			}

		}
		print "|-----DMR detection between groups finished: $cmp\n";
		system("date");
		print "\n\n";

}


