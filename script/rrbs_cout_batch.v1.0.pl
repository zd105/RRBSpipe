#!/usr/bin/perl
use strict;
use Getopt::Long;
use Cwd 'abs_path';
my $usage=<<"USAGE";
  
 name:    rrbs_cout_batch
            
            It is designed for running rrbs bsmap cout in batch model.
 version:1.0
 usage:   perl $0
            -i <str>  map file; 
            -b <str>  bsmap bam files folder path;
            -o <str>  results file path;
            -r <str>  reference genome fa;
            -py2 <str> python2 program;
            -bsmap  <str> mapping program dir(bsmap-2.73/ abs dir);
            -h <str>  help;
 author:  zhangdu
 date:    2017-03-20
USAGE

my ($file,$outfile,$bam,$group,$ref,$python2,$bsmap);
my $help;
GetOptions("i=s" =>  \$file,
           "b=s" => \$bam,
           "o=s" => \$outfile,
		   "r=s" => \$ref,
		   "py2=s" => \$python2,
		   "bsmap=s" => \$bsmap,
           "h=s" => \$help
           );
die $usage if $help;
die $usage unless $file;
die $usage unless $bam;
die $usage unless $ref;
die $usage unless $bsmap;
die $usage unless $python2;

$bam=~s/\/\//\//;

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
       my $path1=$bam."/".$sampleinfo[1]."/".$sampleinfo[1].'.merge.bam';
	   my $cout=$opath.$sampleinfo[1].'.cout';
	   my $signalpbs=$jobpath."/".$sampleinfo[1].".pbs";
		   open SIGNAL, ">$signalpbs" or die "$! : $signalpbs\n";
				print SIGNAL "$python2 $bsmap/methratio.py --ref=$ref --sam-path=$bsmap/samtools --out=$cout $path1 && echo cout done...\necho Start gzip $cout ... 
				gzip -f $cout && echo gzip $cout done\n";
	   close SIGNAL;
	   print PBSall "qsub -N $sampleinfo[1] -l nodes=1:ppn=1 $signalpbs\n";
	   print SGEall "qsub -cwd -l vf=20G -q all.q $signalpbs\n";
  }   
close FILE;
close SGEall;
close PBSall;
###########################################################################################################################
