#!/usr/bin/perl
use strict;
use Getopt::Long;
use FindBin qw($Bin);
use Cwd 'abs_path';
my $usage=<<"USAGE";
  
 name:    BS_Globalpattern_batch
            
            It is designed for plot chr global methy pattern of BS-seq in batch model.
 version:1.0
 usage:   perl $0
            -i <str>  map file; 
            -c <str>  bsmap cout file;
            -o <str>  results file path;
			-r <str>  reference genome;
			-m <int>  min chr to plot; default is 400000;
            -Rscript <int>  Rscript program;
            -h <str>  help;
 author:  zhangdu
 date:    2018-05-29
USAGE

my $p1="$Bin/stat-fa_GC_detect.pl";
my $p2="$Bin/z03.global_pattern.pl";

my ($file,$outfile,$coutdir,$ref,$minChrLen,$Rscript);
my $help;
GetOptions("i=s" =>  \$file,
           "c=s" => \$coutdir,
           "o=s" => \$outfile,
		   "r=s" => \$ref,
		   "m=i" => \$minChrLen,
		   "Rscript=s" => \$Rscript,
           "h=s" => \$help
);

die $usage if $help;
die $usage unless $file;
die $usage unless $coutdir;
die $usage unless $outfile;
die $usage unless $ref;
die $usage unless $Rscript;
$minChrLen ||=400000;

$coutdir=~s/\/\//\//;


# genome stat
print "|--------Making genome GC stat...\n";
system("date");
my $fa_stat="$outfile/genome.GC_stat";
my $chr_list="$outfile/genome.$minChrLen.chr_list";
system("perl $p1 $ref \> $fa_stat");
print "|--------Genome GC stat finished...\n";
system("date");

# select >= 400000 bp chr to plot
print "|--------> $minChrLen chr filtering...\n";
system("perl -alne 'if(\$F[1]>$minChrLen){print \"\$F[0]\\t\$F[1]\"}' $fa_stat \> $chr_list");

my @chr;
my $n=0;
open CHR, $chr_list or die "$!\n";
while(<CHR>){
	chomp;
	my @a=split;
	push @chr,$a[0];
	$n++;
}
print "|--------> Total $n chr methylation pattern to plot...\n";
system("date");

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
		   foreach my $chrm(@chr){
			   print SIGNAL "perl $p2 -I $cout -N $chrm -B 10000 -O $opath -R $Rscript && $chrm global methylation pattern analysis finished..\n";
		   }
	   close SIGNAL;
	   print PBSall "qsub -N $sampleinfo[1] -l nodes=1:ppn=1 $signalpbs\n";
	   print SGEall "qsub -cwd -l vf=2G -q all.q $signalpbs\n";
  }   
close FILE;
close SGEall;
close PBSall;
###########################################################################################################################
