#!/usr/bin/perl
use strict;
use Getopt::Long;
use FindBin qw($Bin);
use Cwd 'abs_path';
my $usage=<<"USAGE";
  
 name:    $0
            
            It is designed for running RRBS data clean in batch model.
 version:1.0
 usage:   perl $0
            -i <str>  map file; 
            -p <str>  clean data folder path, gz file path;
            -o <str>  results file path;
            -m <int>  0 for RRBS(default); 1 for DRRBS;
            -py3 <str>  python3 program;
            -cut <str> cutadapt program;
            -h <str>  help;
 author:  zhangdu
 date:    2018-05-02
USAGE

my $p1="$Bin/00_FQ_trim.2.pl";
my $p2="$Bin/cut_rrbs.v1.0.pl";
my $p3="$Bin/02_FQ_clean.2.pl";
my $p4="$Bin/01_FQ_pas.pl";

my ($map,$outfile,$fqpath,$python3,$cutadapt,$mode);
my $help;
GetOptions("i=s" =>  \$map,
           "p=s" => \$fqpath,
           "o=s" => \$outfile,
           "m=s" => \$mode,
           "py3=s" => \$python3,
           "cut=s" => \$cutadapt,
           "h=s" => \$help
           );
die $usage if $help;
die $usage unless $map;
die $usage unless $fqpath;
die $usage unless $python3;
die $usage unless $cutadapt;
$mode ||=0;

if ($fqpath eq ''){
   my @outtmp=split(/\//,abs_path($map));
   $outfile=abs_path($map);
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
system ("date");
open FILE, $map
         or die "can not open $map:$!";     #打开文件   
while(<FILE>){   
       chomp $_;
       if (/^#Group/){next};
       my @sampleinfo=split(/\t/,$_);
       print "Deal with $sampleinfo[1] : $sampleinfo[2]\t$sampleinfo[3]\n";
	   if($sampleinfo[3] eq ""){ # for single end sequencing
		   my $path1=$fqpath."/".$sampleinfo[2];
		   my $opath=$outfile."/".$sampleinfo[1];
		   system("mkdir -p $opath");
		   my $temp1=$opath."/".$sampleinfo[1].".fq.gz";
		   my $temp4=$opath."/".$sampleinfo[1].".cut1.fq.gz";
		   my $temp5=$opath."/".$sampleinfo[1].".cut2.fq.gz";
		   my $ofile=$opath."/".$sampleinfo[1].".clean";
		   my $signalpbs=$jobpath."/".$sampleinfo[1].".pbs";
		   open SIGNAL, ">$signalpbs" or die "$! : $signalpbs\n";
		   print SIGNAL "perl $p1 $path1 1 $temp1 && echo fq1 head revise done..
		   $python3 $cutadapt -a AGATCGGAAGAGC -a AGATCGGAAGAGC -f fastq -m 35 -n 2 -o $temp4 $temp1 && echo cutting adapter is done..
		   perl $p2 -i $temp4 -m $mode -o $temp5 && echo cut rrbs is done..
		   perl $p3 $temp5 $ofile && echo Clean is done..\n";
		   close SIGNAL;
		   print PBSall "qsub -N $sampleinfo[1] -l nodes=1:ppn=2 $signalpbs\n";
		   print SGEall "qsub -cwd -l vf=10G -q all.q $signalpbs\n";
		}
		else{ # for pair end sequencing
		my $path1=$fqpath."/".$sampleinfo[2];
		my $path2=$fqpath."/".$sampleinfo[3];
	   my $opath=$outfile."/".$sampleinfo[1];
	   system("mkdir -p $opath");
	   my $temp1=$opath."/".$sampleinfo[1].".1.fq.gz";
	   my $temp2=$opath."/".$sampleinfo[1].".2.fq.gz";
	   my $temp3=$opath."/".$sampleinfo[1].".fq.gz";
	   my $temp4=$opath."/".$sampleinfo[1].".cut1.fq.gz";
	   my $temp5=$opath."/".$sampleinfo[1].".cut2.fq.gz";
	   my $ofile=$opath."/".$sampleinfo[1].".clean";
       my $signalpbs=$jobpath."/".$sampleinfo[1].".pbs";
	   open SIGNAL, ">$signalpbs" or die "$! : $signalpbs\n";
	    print SIGNAL "perl $p1 $path1 1 $temp1 && echo fq1 head revise done..
		perl $p1 $path2 2 $temp2 && echo fq2 head revise done..
		perl $p4 $temp1 $temp2 $temp3 && echo fq1 and fq2 merge done..
		$python3 $cutadapt -a AGATCGGAAGAGC -a AGATCGGAAGAGC -f fastq -m 35 -n 2 -o $temp4 $temp3 && echo cutting adapter is done..
		perl $p2 -m $mode -i $temp4 -o $temp5 && echo cut rrbs is done..
		perl $p3 $temp5 $ofile && echo Clean is done..\n";
		close SIGNAL;
		print PBSall "qsub -N $sampleinfo[1] -l nodes=1:ppn=2 $signalpbs\n";
		print SGEall "qsub -cwd -l vf=10G -q all.q $signalpbs\n";
		}
}   
close FILE;
close SGEall;
close PBSall;
#END
###########################################################################################################################
