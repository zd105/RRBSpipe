#!/usr/bin/perl
use strict;
use Getopt::Long;
use Cwd 'abs_path';
my $usage=<<"USAGE";
  
 name:    BS_bedgragh_batch
            
            It is designed for generate .bedgraph from cout of  BS-seq in batch model.
 version:1.0
 usage:   perl $0
            -i <str>  map file; 
            -c <str>  bsmap cout file;
            -o <str>  results file path;
            -d <int>  >= dx CpG sites with be keeped; default is 5;
            -bedtools <str> bedtools dir;
            -h <str>  help;
 author:  zhangdu
 date:    2017-03-20
USAGE


my ($file,$outfile,$coutdir,$depth,$bedtools);
my $help;
GetOptions("i=s" =>  \$file,
           "c=s" => \$coutdir,
           "o=s" => \$outfile,
		   "d=i" => \$depth,
		   "bedtools=s" => \$bedtools,
           "h=s" => \$help
           );
die $usage if $help;
die $usage unless $file;
die $usage unless $coutdir;
die $usage unless $bedtools;
$depth ||= 5;

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
	   my $opath="$outfile\/$sampleinfo[1]\/";
	   my $out0="$outfile\/$sampleinfo[1]\/$sampleinfo[1]\_$depth"."x"."C\.bedgraph";
	   my $out1="$outfile\/$sampleinfo[1]\/$sampleinfo[1]\_$depth"."x"."CG\.bedgraph";
	   my $out2="$outfile\/$sampleinfo[1]\/$sampleinfo[1]\_$depth"."x"."CHG\.bedgraph";
	   my $out3="$outfile\/$sampleinfo[1]\/$sampleinfo[1]\_$depth"."x"."CHH\.bedgraph";
	   system("mkdir -p $opath");
	   my $cout="$coutdir\/$sampleinfo[1]\/$sampleinfo[1]\.cout\.gz";
	   my $signalpbs=$jobpath."/".$sampleinfo[1].".pbs";
		   open SIGNAL, ">$signalpbs" or die "$! : $signalpbs\n";
				print SIGNAL "
zcat $cout \| perl -alne 'if(\$F[6]+\$F[7] >= $depth){print join \"\\t\",\$F[0],\$F[1],\$F[1]+1,\$F[5]}' \| $bedtools sort -i \> $out0 && echo -e \">=$depth x  C site filtering done..\"
zcat $cout \| perl -alne 'if(\$F[3] eq \"CG\" \&\& \$F[6]+\$F[7] >= $depth){print join \"\\t\",\$F[0],\$F[1],\$F[1]+1,\$F[5]}' \| $bedtools sort -i \> $out1 && echo -e \">=$depth x  CG site filtering done..\"
zcat $cout \| perl -alne 'if(\$F[3] eq \"CHG\" \&\& \$F[6]+\$F[7] >= $depth){print join \"\\t\",\$F[0],\$F[1],\$F[1]+1,\$F[5]}' \| $bedtools sort -i \> $out2 \&\& echo -e \">=$depth x  CHG site filtering done..\"
zcat $cout \| perl -alne 'if(\$F[3] eq \"CHH\" \&\& \$F[6]+\$F[7] >= $depth){print join \"\\t\",\$F[0],\$F[1],\$F[1]+1,\$F[5]}' \| $bedtools sort -i \> $out3 \&\& echo -e \">=$depth x  CHH site filtering done..\"\n";
	   close SIGNAL;
	   print PBSall "qsub -N $sampleinfo[1] -l nodes=1:ppn=1 $signalpbs\n";
	   print SGEall "qsub -cwd -l vf=2G -q all.q $signalpbs\n";
  }   
close FILE;
close SGEall;
close PBSall;
###########################################################################################################################
