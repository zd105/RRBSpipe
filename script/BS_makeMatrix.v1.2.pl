#!/usr/bin/perl
use strict;
use Getopt::Long;
use FindBin qw($Bin);
use Cwd 'abs_path';
my $usage=<<"USAGE";
  
 name:    BS_makeMatrix
            
            It is designed for generate standard methylation matrix and do PCA,PCC and Cluster analysis from sample .bedgraph of  BS-seq.
 version:1.1
 usage:   perl $0
            -i <str>  map file; 
            -b <str>  .bedgraph file dir;
            -t <str>  methy type to analysis: C,CG,CHG,CHH or combine of them, "," splited like: CG,CHG,CHH;
            -o <str>  results file path;
            -d <int>  the cut depth of C site;
            -bedtools <str>  bedtools excutable file;
            -Rscript <str>  Rscript program;
            -h <str>  help;
 author:zhangdu
 date: 2018-08-08
USAGE

my $p1="$Bin/makeMatrix_merge.pl";
my $p2="$Bin/makeMatrix_cluster.pl";

my ($file,$outfile,$depth,$bed,$bedtools,$type,$Rscript);
my $help;
GetOptions("i=s" =>  \$file,
           "b=s" => \$bed,
		   "t=s" => \$type,
		   "d=i" => \$depth,
		   "bedtools=s" => \$bedtools,
		   "Rscript=s" => \$Rscript,
           "o=s" => \$outfile,
           "h=s" => \$help
		   );
die $usage if $help;
die $usage unless $file;
die $usage unless $outfile;
die $usage unless $bed;
die $usage unless $depth;
die $usage unless $Rscript;
die $usage unless $bedtools;
$type ||= "CG";

my (@C,@CG,@CHG,@CHH,@sample);
print "Reading map file...\n";
open FILE, $file
         or die "can not open $file:$!";     #打开文件   
my $group="$outfile\/sample_group.txt";
open GROUP, ">$group" or die "can not open $group:$!";
  while(<FILE>){   
       chomp $_;
       next if(/^#Group/);
       my @sampleinfo=split(/\t/,$_);
       print $sampleinfo[1]."\n";
	   print GROUP $sampleinfo[0]."\n";
	   #my $opath="$outfile\/$sampleinfo[1]\/";
	   my $in0="$bed\/$sampleinfo[1]\/$sampleinfo[1]\_$depth"."x"."C\.bedgraph";
	   my $in1="$bed\/$sampleinfo[1]\/$sampleinfo[1]\_$depth"."x"."CG\.bedgraph";
	   my $in2="$bed\/$sampleinfo[1]\/$sampleinfo[1]\_$depth"."x"."CHG\.bedgraph";
	   my $in3="$bed\/$sampleinfo[1]\/$sampleinfo[1]\_$depth"."x"."CHH\.bedgraph";
	   push @C,$in0;
	   push @CG,$in1;
	   push @CHG,$in2;
	   push @CHH,$in3;
	   push @sample,$sampleinfo[1];
  }   
close GROUP;
close FILE;

my $c=join(",", @C);
my $cg=join(",", @CG);
my $chg=join(",", @CHG);
my $chh=join(",", @CHH);
my $s=join(",", @sample);

my @mode=split(/,/,$type);

foreach my $m(@mode){
if($m eq "C"){
	# analysis mC
	print "Making $depth x C  methylation matrix file...\n";
	system("date");
	my $mC="$outfile\/mC";
	system("mkdir -p $mC");
	my $oc="$mC\/$depth"."x"."C\.methy\_Matrix.txt";
	system("perl $p1 --in $c --head $s --out $oc -b $bedtools");
	print "Making $depth x C  methylation clustering...\n";
	system("date");
	system("perl $p2 --in $oc --class $group --pca --pcc --clust --out $oc --r $Rscript");
}

if($m eq "CG"){
#analysis mCG
	print "Making $depth x CG  methylation matrix file...\n";
	system("date");
	my $mCG="$outfile\/mCG";
	system("mkdir -p $mCG");
	my $ocg="$mCG\/$depth"."x"."CG\.methy\_Matrix.txt";
	system("perl $p1 --in $cg --head $s --out $ocg -b $bedtools");
	print "Making $depth x CG  methylation clustering...\n";
	system("date");
	system("perl $p2 --in $ocg --class $group --pca --pcc --clust --out $ocg --r $Rscript");
}

if($m eq "CHG"){
	#analysis mCHG
	print "Making $depth x CHG  methylation matrix file...\n";
	system("date");
	my $mCHG="$outfile\/mCHG";
	system("mkdir -p $mCHG");
	my $ochg="$mCHG\/$depth"."x"."CHG\.methy\_Matrix.txt";
	system("perl $p1 --in $chg --head $s --out $ochg -b $bedtools");
	print "Making $depth x CHG  methylation clustering...\n";
	system("date");
	system("perl $p2 --in $ochg --class $group --pca --pcc --clust --out $ochg --r $Rscript");
}


if($m eq "CHH"){
	#analysis mCHH
	print "Making $depth x CHH  methylation matrix file...\n";
	system("date");
	my $mCHH="$outfile\/mCHH";
	system("mkdir -p $mCHH");
	my $ochh="$mCHH\/$depth"."x"."CHH\.methy\_Matrix.txt";
	system("perl $p1 --in $chh --head $s --out $ochh -b $bedtools");
	print "Making $depth x CHH  methylation clustering...\n";
	system("date");
	system("perl $p2 --in $ochh --class $group --pca --pcc --clust --out $ochh --r $Rscript");
}
}

###########################################################################################################################
