#!/usr/bin/perl
use strict;
use Getopt::Long;
use Cwd 'abs_path';
my $usage=<<"USAGE";
  
 name:    rrbs_control_batch
            
            It is designed for running rrbs Control DNA CT convertion rate  in batch model.
 version:1.0
 usage:   perl $0
            -i <str>  map file; 
            -p <str>  fastq files folder path;
            -o <str>  results file path;
            -m <str>  s for single end; p for pair end;
            -r <str>  control.fa;
            -bsmap <str> bsmap program dir(bsmap-2.73/ abs dir);
            -t <str>  Specifies the number of files which can be processed simultaneously.  
                      Each thread will be allocated 250MB of memory so you shouldn't run more 
                      threads than your available memory will cope with, and not more than 6 threads on a 32 bit machine
            -h <str>  help;
 author:  zhangdu
 date:    2017-03-20
USAGE

my ($file,$outfile,$fqpath,$threads,$mode,$ref,$bsmap);
my $help;
GetOptions("i=s" =>  \$file,
           "p=s" => \$fqpath,
           "o=s" => \$outfile,
		   "m=s" => \$mode,
		   "r=s" => \$ref,
		   "bsmap=s" => \$bsmap,
           "t=i" => \$threads,
           "h=s" => \$help
           );
die $usage if $help;
die $usage unless $file;
die $usage unless $fqpath;
die $usage unless $ref;
die $usage unless $bsmap;
$threads=8 unless $threads;
$mode="p" unless $mode;
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
	   my $opath=$outfile."/".$sampleinfo[1]."/";
	   system("mkdir -p $opath");
       my $path1=$fqpath.$sampleinfo[1]."/".$sampleinfo[1].'.clean.1.fq.gz';
       my $path2=$fqpath.$sampleinfo[1]."/".$sampleinfo[1].'.clean.2.fq.gz';
	   my $path3=$fqpath.$sampleinfo[1]."/".$sampleinfo[1].'.clean.single.fq.gz';
	   my $sam1=$opath.$sampleinfo[1].'.control.pe.sam';
	   my $sam2=$opath.$sampleinfo[1].'.control.se.sam';
	   my $bam1=$opath.$sampleinfo[1].'.control.pe.bam';
	   my $bam2=$opath.$sampleinfo[1].'.control.se.bam';
	   my $bam3=$opath.$sampleinfo[1].'.control.merge.bam';
	   my $stat=$opath.$sampleinfo[1].'.control.bsmap.result';
	   my $cout=$opath.$sampleinfo[1].'.control.cout';
	   my $signalpbs=$jobpath."/".$sampleinfo[1].".pbs";
		   open SIGNAL, ">$signalpbs" or die "$! : $signalpbs\n";
	       if($mode eq "p"){
				print SIGNAL "$bsmap/bsmap -a $path1 -b $path2 -d $ref -o $sam1 -v 0.1 -g 1 -p $threads && echo bsmap pe is done..
				cd $bsmap
				sh $bsmap/sam2bam.sh $sam1 && echo sam 2 bam pe is done..
				rm $sam1
				$bsmap/bsmap -a $path3 -d $ref -o $sam2 -v 0.1 -g 1 -p $threads && echo bsmap se is done..
				sh $bsmap/sam2bam.sh $sam2 && echo sam 2 bam se is done..
				rm $sam2
				$bsmap/samtools/samtools merge -f $bam3 $bam1 $bam2 && echo merge is done..
				$bsmap/samtools/samtools index $bam3 && echo index merge is done..
				$bsmap/samtools/samtools flagstat  $bam3 > $stat && echo stat is done..
				/public/software/bin/python $bsmap/methratio.py --ref=$ref --sam-path=$bsmap/samtools --out=$cout $bam3 && echo cout done...\necho Start gzip $cout ...
				gzip -f $cout && echo gzip $cout done\n";
			}elsif($mode eq "s"){
				print SIGNAL "$bsmap/bsmap -a $path3 -d $ref -o $sam2 -v 0.1 -g 1 -p $threads && echo bsmap se is done..
				cd $bsmap
				sh $bsmap/sam2bam.sh $sam2 && echo sam 2 bam se is done..
				mv $bam2 $bam3 && echo bam rename is done..
				$bsmap/samtools/samtools index $bam3 && echo index merge is done..
				$bsmap/samtools/samtools flagstat  $bam3 > $stat && echo stat is done..
				/public/software/bin/python $bsmap/methratio.py --ref=$ref --sam-path=$bsmap/samtools --out=$cout $bam3 && echo cout done...\necho Start gzip $cout ...
				gzip -f $cout && echo gzip $cout done\n";
			}
	   close SIGNAL;
	   print PBSall "qsub -N $sampleinfo[1] -l nodes=1:ppn=$threads $signalpbs\n";
	   print SGEall "qsub -cwd -l vf=8G -q all.q -pe smp $threads $signalpbs\n";
	   }
close FILE;
close SGEall;
close PBSall;
###########################################################################################################################
