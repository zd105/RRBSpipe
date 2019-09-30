#!/usr/bin/perl
use strict;
use Getopt::Long;
use Cwd 'abs_path';
my $usage=<<"USAGE";

name:    rrbs_mapping_batch

         It is designed for running rrbs mapping in batch model.
version:1.0
usage:   perl $0
              -i <str>  map file; 
              -p <str>  fastq files folder path;
              -o <str>  results file path;
              -m <str>  s for single end; p for pair end;
              -r <str>  reference genome fa;\
              -t <int>  threads to use. default is 8;
              -soft <str> mapping program. 0: bsmap(default); 1: bsmark;
                   For bsmap:
                       -v  <float> if this value is between 0 and 1, it's interpreted as the mismatch rate w.r.t to the read length.
                                   otherwise it's interpreted as the maximum number of mismatches allowed on a read, <=15.
                                   example: -v 5 (max #mismatches = 5), -v 0.1 (max #mismatches = read_length * 10%)
                                   default=0.08.
                       -g  <int>   gap size, BSMAP only allow 1 continuous gap (insert or deletion) with up to 3 nucleotides
                                   default=1
                       -n  [0,1]   set mapping strand information. default: 0
                                   -n 0: only map to 2 forward strands, i.e. BSW(++) and BSC(-+), 
                                   for PE sequencing, map read#1 to ++ and -+, read#2 to +- and --.
                                   -n 1: map SE or PE reads to all 4 strands, i.e. ++, +-, -+, -- 
                                   generally normal BS-seq is 0; single cell BS-seq is 1. 
               -softdir <str> mapping program dir(bsmap-2.73/ abs dir);
               -h <str>  help;
author:  zhangdu
date:    2017-03-20
USAGE

my ($file,$outfile,$fqpath,$threads,$mode,$ref,$soft,$mismatch,$gap,$softdir,$n);
my $help;
GetOptions("i=s" =>  \$file,
		"p=s" => \$fqpath,
		"o=s" => \$outfile,
		"m=s" => \$mode,
		"r=s" => \$ref,
		"t=i" => \$threads,
		"soft=s" => \$soft,
		"v=s" => \$mismatch,
		"g=s" => \$gap,
		"n=s" => \$n,
		"softdir=s" => \$softdir,
		"h=s" => \$help
		);
die $usage if $help;
die $usage unless $file;
die $usage unless $fqpath;
die $usage unless $ref;
$threads=4 unless $threads;
die $usage unless $softdir;
$soft ||=0;
if($soft == 0){
	$mismatch ||=0.08;
	$gap ||=1;
	$n ||=0;
}
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
		next if($.==1);
		my @sampleinfo=split(/\t/,$_);
		print $sampleinfo[1]."\n";
		my $opath=$outfile."/".$sampleinfo[1]."/";
		system("mkdir -p $opath");
		my $path1=$fqpath.$sampleinfo[1]."/".$sampleinfo[1].'.clean.1.fq.gz';
		my $path2=$fqpath.$sampleinfo[1]."/".$sampleinfo[1].'.clean.2.fq.gz';
		my $path3=$fqpath.$sampleinfo[1]."/".$sampleinfo[1].'.clean.single.fq.gz';
		my $sam1=$opath.$sampleinfo[1].'.pe.sam';
		my $sam2=$opath.$sampleinfo[1].'.se.sam';
		my $bam1=$opath.$sampleinfo[1].'.pe.bam';
		my $bam2=$opath.$sampleinfo[1].'.se.bam';
		my $bam3=$opath.$sampleinfo[1].'.merge.bam';
		my $stat=$opath.$sampleinfo[1].'.mapping.stat';
		my $signalpbs=$jobpath."/".$sampleinfo[1].".pbs";
		open SIGNAL, ">$signalpbs" or die "$! : $signalpbs\n";
	if($soft ==0){
		if($mode eq "p"){
			print SIGNAL "$softdir/bsmap -a $path1 -b $path2 -d $ref -o $sam1 -v $mismatch -g $gap -n $n  -p $threads -R -u && echo bsmap pe is done..
				cd $softdir
				sh $softdir/sam2bam.sh $sam1 && echo sam 2 bam pe is done..
				mv $bam1 $bam3 && echo bam rename is done..
				$softdir/samtools/samtools index $bam3 && echo index merge is done..
				$softdir/samtools/samtools flagstat $bam3 > $stat && echo stat is done..\n";
		}elsif($mode eq "s"){
			print SIGNAL "$softdir/bsmap -a $path3 -d $ref -o $sam2 -v $mismatch -g $gap -n $n  -p $threads -R -u && echo bsmap se is done..
				cd $softdir
				sh $softdir/sam2bam.sh $sam2 && echo sam 2 bam se is done..
				mv $bam2 $bam3 && echo bam rename is done..
				$softdir/samtools/samtools index $bam3 && echo index merge is done..
				$softdir/samtools/samtools flagstat  $bam3 > $stat && echo stat is done..\n";
		}
	}elsif($soft ==1){
		#bismark mapping 
	}

		close SIGNAL;
		print PBSall "qsub -N $sampleinfo[1] -l nodes=1:ppn=$threads $signalpbs\n";
		print SGEall "qsub -cwd -l vf=8G -pe smp $threads -q all.q $signalpbs\n";
	}
close FILE;
close SGEall;
close PBSall;
###########################################################################################################################
