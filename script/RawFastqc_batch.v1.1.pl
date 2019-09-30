#!/usr/bin/perl
use strict;
use Getopt::Long;
use Cwd 'abs_path';
my $usage=<<"USAGE";
  
 name:    RawFastqc_batch
            
            It is designed for running fastqc for any rawdata in batch model.
 version:1.0
 usage:   perl $0
            -i <str>  map file; 
            -p <str>  fastq files folder path;
            -o <str>  results file path;
            -t <str>  Specifies the number of files which can be processed simultaneously.  
                      Each thread will be allocated 250MB of memory so you shouldn't run more 
                      threads than your available memory will cope with, and not more than 6 threads on a 32 bit machine
            -fastqc <str>  fastqc program;
            -h <str>  help;
 author:  zhangdu
 date:    2017-03-20
USAGE

my ($file,$outfile,$fqpath,$threads,$fastqc);
my $help;
GetOptions("i=s" =>  \$file,
           "p=s" => \$fqpath,
           "o=s" => \$outfile,
           "t=s" => \$threads,
           "fastqc=s" => \$fastqc,
           "h=s" => \$help
           );
die $usage if $help;
die $usage unless $file;
die $usage unless $fqpath;
$threads=1 unless $threads;
if ($fqpath eq ''){
   my @outtmp=split(/\//,abs_path($file));
   $outfile=abs_path($file);
   $outfile=~s/$outtmp[-1]//;
   $outfile=~s/\/\//\//;
}
$fqpath=~s/\/\//\//;

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
	   my $opath=$outfile;
       my $path1=$fqpath."/".$sampleinfo[2];
       my $path2=$fqpath."/".$sampleinfo[3];
       my $totalpath.=$path1." ".$path2;
	   my $signalpbs=$jobpath."/".$sampleinfo[1].".pbs";
	   open SIGNAL, ">$signalpbs" or die "$! : $signalpbs\n";
	   print SIGNAL "$fastqc -t $threads -o $opath $totalpath\n";
	   close SIGNAL;
	   print PBSall "qsub -N $sampleinfo[1] -l nodes=1:ppn=$threads $signalpbs\n";
	   print SGEall "qsub -cwd -l vf=1G -q all.q $signalpbs\n";
  }   
close FILE;
close PBSall;
close SGEall;
###########################################################################################################################
