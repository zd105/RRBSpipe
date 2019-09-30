#!/usr/bin/perl
use strict;
use Getopt::Long;
use FindBin qw($Bin $Script);
use Cwd 'abs_path';
my $usage=<<"USAGE";
  
 name:    rrbs_ElementMethy_batch
            
            It is designed for running gene element methylation level of BS-seq in batch model.
 version:1.0
 usage:   perl $0
            -i <str>  map file; 
            -c <str>  bsmap cout file;
            -o <str>  results file path;
            -db <str> UCSC or NCBI or ensembl;
            -r <str>  reference genome;
            -anno <str>  gene annotation file;
                         --UCSC: refGene.txt.gz
                         --NCBI: gff or gff
                         --ensembl: gff3
            -cgi <str> 1.if it is a mammal, species.cpgIslandExt.txt.gz download from UCSC;
                       2.if it is a mammal, without UCSC cgi files: "build";
                       3.other species has no CGI definition,just do not assign this parameter;
            -repeat  <str> UCSC repeats annotation gz file;
            -Rscript <str> Rscript program;
            -h <str>  help;
 author:  zhangdu
 date:    2018-05-29
USAGE

my $p1="$Bin/parse_UCSC_refGene.sh";
my $p2="$Bin/parse_NCBI_gff3.sh";
my $p3="$Bin/CGI.element_finder.v1.0.sh";
my $p4="$Bin/CGI.element_finder_forUCSC.v1.0.sh";
my $p5="$Bin/z04.elements_methyl.v1.1.sh";
my $p6="$Bin/parse_UCSC_repeats.sh";

my ($ref,$file,$outfile,$coutdir,$db,$anno,$cgi,$repeats,$Rscript);
my $help;
GetOptions("i=s" =>  \$file,
           "c=s" => \$coutdir,
           "o=s" => \$outfile,
		   "db=s" => \$db,
		   "r=s" => \$ref,
		   "anno=s" => \$anno,
		   "cgi=s" => \$cgi,
		   "repeat=s" => \$repeats,
		   "Rscript=s" => \$Rscript,
           "h=s" => \$help
);

die $usage if $help;
die $usage unless $file;
die $usage unless $coutdir;
die $usage unless $outfile;
die $usage unless $db;
die $usage unless $ref;
die $usage unless $anno;
die $usage unless $repeats;
die $usage unless $Rscript;
$cgi ||="";

$coutdir=~s/\/\//\//;

#gene element extraction
print "|--------gene element extracting from $anno...\n";
system("date");
system("mkdir -p $outfile/element");
if($db eq "UCSC"){
	system("cd $outfile/element \&\& sh $p1 $ref $anno $outfile/element genome");
}elsif($db eq "NCBI"){
	system("cd $outfile/element \&\& sh $p2 $ref $anno $outfile/element genome");
}
print "|--------gene element extraction finished...\n";
system("date");

#CG Island and CG Island shore extraction
print "|--------cgi,cgi shore and shelf extracting from start...\n";
system("date");
if($cgi ne ""){
	if($cgi eq "build"){
		print "|--------Building cgi.bed of $ref by Emboss cpgplot tools...\n";
		system("sh $p3 $ref $outfile/element genome");
	}else{
		print "|--------cgi and cgi shore extracting from $cgi...\n";
		system("sh $p4 $ref $cgi $outfile/element genome");
	}
}
print "|--------cgi,cgi shore and shelf extracting  finished...\n";
system("date");

#genome repeat elements extraction
print "|--------Repeat element extracting from $repeats...\n";
system("date");
system("sh $p6 $repeats $outfile/element");
print "|--------Repeat element extraction finished...\n";
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
			print SIGNAL "sh $p5 $outfile/element $cout $opath CG $sampleinfo[1] $Rscript cgi\n";
	   close SIGNAL;
	   print PBSall "qsub -N $sampleinfo[1] -l nodes=1:ppn=1 $signalpbs\n";
	   print SGEall "qsub -cwd -l vf=2G -q all.q $signalpbs\n";
  }   
close FILE;
close SGEall;
close PBSall;
###########################################################################################################################
