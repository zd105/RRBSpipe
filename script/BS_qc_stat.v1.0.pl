#!/usr/bin/perl
use strict;
use Getopt::Long;
use FindBin qw($Bin);
use Cwd 'abs_path';
my $usage=<<"USAGE";
  
 name:    BS_qc_stat
            
            It is designed for running bs qc stat in batch model.
 version:1.0
 usage:   perl $0
            -i <str>  map file; 
            -p <str>  fastq files folder path;
            -o <str>  results file path;
            -h <str>  help;
 author:  zhangdu
 date:    2017-03-20
USAGE

my $p1="$Bin/02_FQ_stat.pl";

my ($file,$outfile,$fqpath);
my $help;
GetOptions("i=s" =>  \$file,
           "p=s" => \$fqpath,
           "o=s" => \$outfile,
           "h=s" => \$help
           );
die $usage if $help;
die $usage unless $file;
die $usage unless $fqpath;
if ($fqpath eq ''){
   my @outtmp=split(/\//,abs_path($file));
   $outfile=abs_path($file);
   $outfile=~s/$outtmp[-1]//;
   $outfile=~s/\/\//\//;
}
$fqpath=~s/\/\//\//;

my $jobpath="$outfile/jobs";
if (-e $jobpath){
	print STDOUT "$jobpath exists!";
}else{
	system("mkdir -p $jobpath");
}

open PBSall, ">$jobpath/all.pbs" or die "$! : all.pbs\n";
open SGEall, ">$jobpath/all.sge" or die "$! : all.sge\n";
print "Reading map file...\n";
my $totalpath;
system ("date");
open FILE, $file
         or die "can not open $file:$!";     #打开文件   
  while(<FILE>){   
       chomp $_;
       if (/^#Group/){next}
       my @sampleinfo=split(/\t/,$_);
       print $sampleinfo[1]."\n";
	   my $rpath1=$fqpath."/".$sampleinfo[1]."/".$sampleinfo[1].'.fq.gz';
	   #my $rpath2=$fqpath.$sampleinfo[1]."/".$sampleinfo[1].'.2.fq.gz';
       my $path1=$fqpath."/".$sampleinfo[1]."/".$sampleinfo[1].'.clean.1.fq.gz';
       my $path2=$fqpath."/".$sampleinfo[1]."/".$sampleinfo[1].'.clean.2.fq.gz';
	   my $path4=$fqpath."/".$sampleinfo[1]."/".$sampleinfo[1].'.cut1.fq.gz';
	   my $opath=$outfile."/".$sampleinfo[1];
	   system("mkdir -p $opath");
	   my $stat1=$opath."/".$sampleinfo[1].'.raw.xls';
	   my $stat2=$opath."/".$sampleinfo[1].'.noAdapter.xls';
	   my $stat3=$opath."/".$sampleinfo[1].'.clean.xls';
       $totalpath.=$path1." ".$path2." ";
	   my $signalpbs=$jobpath."/".$sampleinfo[1].".pbs";
	   open SIGNAL, ">$signalpbs" or die "$! : $signalpbs\n";
	   print SIGNAL "
perl $p1 $rpath1 $stat1 && echo rawdata stat done..
perl $p1 $path4 $stat2 && echo adapter free data stat done..
perl $p1 $path1 $path2 $stat3 && echo cleandata stat done..\n";
	   close SIGNAL;
	   print PBSall "qsub -N $sampleinfo[1] -l nodes=1:ppn=1 $signalpbs\n";
	   print SGEall "qsub -cwd -l vf=2G -q all.q $signalpbs\n";
  }   
close FILE;
close PBSall;
###########################################################################################################################
