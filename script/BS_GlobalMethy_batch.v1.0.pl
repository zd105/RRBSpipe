#!/usr/bin/perl
use strict;
use Getopt::Long;
use FindBin qw($Bin);
use Cwd 'abs_path';
my $usage=<<"USAGE";
  
 name:    BS_GlobalMethy_batch
            
            It is designed for running Global Methylation profile of BS-seq in batch model.
 version:1.0
 usage:   perl $0
            -i <str>  map file; 
            -c <str>  bsmap cout file;
            -o <str>  results file path;
            -d <int>  max plot depth;default is 30x;
            -r <str>  reference genome fa;
            -Rscript <str>  Rscript program;
            -h <str>  help;
 author:  zhangdu
 date:    2017-03-20
USAGE

my $p1="$Bin/z01.dep_coverage.pl";
my $p2="$Bin/z02.mC_seqlogo.sh";

my ($file,$outfile,$coutdir,$group,$ref,$maxplotdepth,$Rscript);
my $help;
GetOptions("i=s" =>  \$file,
           "c=s" => \$coutdir,
           "o=s" => \$outfile,
		   "d=i" => \$maxplotdepth,
		   "r=s" => \$ref,
		   "Rscript=s" => \$Rscript,
           "h=s" => \$help
           );
die $usage if $help;
die $usage unless $file;
die $usage unless $coutdir;
die $usage unless $ref;
die $usage unless $Rscript;
$maxplotdepth ||= 30;

$coutdir=~s/\/\//\//;

my $jobpath="$outfile/jobs";
#if (-e $jobpath){
#	print STDOUT "$jobpath exists!";
#}else{
    system("mkdir -p $jobpath");
#}

open PBSall, ">$jobpath/all.pbs" or die "$! : all.pbs\n";
open SGEall, ">$jobpath/all.sge" or die "$! : all.sge\n";
print "Reading map file...\n";
#my $totalpath;
system ("date");
open FILE, $file
         or die "can not open $file:$!";     #打开文件   
  while(<FILE>){   
       chomp $_;
       next if(/^#Group/);
       my @sampleinfo=split(/\t/,$_);
       print $sampleinfo[1]."\n";
	   my $opath=$outfile."/".$sampleinfo[1]."/";
	   system("mkdir -p $opath");
	   my $cout=$coutdir."/".$sampleinfo[1]."/".$sampleinfo[1].'.cout.gz';
	   my $signalpbs=$jobpath."/".$sampleinfo[1].".pbs";
		   open SIGNAL, ">$signalpbs" or die "$! : $signalpbs\n";
				print SIGNAL "perl $p1 -i $cout -o $opath -n $sampleinfo[1] -d $maxplotdepth -r $Rscript
				sh $p2 $sampleinfo[1] $cout $opath $ref $Rscript\n";
	   close SIGNAL;
	   print PBSall "qsub -N $sampleinfo[1] -l nodes=1:ppn=1 $signalpbs\n";
	   print SGEall "qsub -cwd -l vf=2G -q all.q $signalpbs\n";
  }   
close FILE;
close SGEall;
close PBSall;
###########################################################################################################################
