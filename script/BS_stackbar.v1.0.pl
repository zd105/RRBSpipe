#!/usr/bin/perl
use strict;
use Getopt::Long;
use FindBin qw($Bin $Script);
use Cwd 'abs_path';
my $usage=<<"USAGE";

name:    rrbs_stackbar

         It is designed for generate standard methylation matrix and do PCA,PCC and Cluster analysis from sample .bedgraph of  BS-seq.
         version:1.1
         usage:   perl $0
                    -i <str>  map file; 
                    -b <str>  .bedgraph file dir;
                    -t <str>  methy type to analysis: C,CG,CHG,CHH or combine of them, "," splited like: CG,CHG,CHH;
                    -o <str>  results file path;
                    -d <int>  the cut depth of C site;
                    -bedtools <str>  bedtools excutable file;
                    -Rscript <str>  Rscript program;
                    -h <str>  help;
         author:zhangdu
         date: 2018-08-08
USAGE

my $p1="$Bin/makeMatrix_merge.pl";
my $p2="$Bin/methy_stack_bar.v1.1.R";

my ($file,$outfile,$depth,$bed,$bedtools,$type,$Rscript);
my $help;
GetOptions("i=s" =>  \$file,
		"b=s" => \$bed,
		"t=s" => \$type,
		"d=i" => \$depth,
		"bedtools=s" => \$bedtools,
		"Rscript=s" => \$Rscript,
		"o=s" => \$outfile,
		"h=s" => \$help
		);
die $usage if $help;
die $usage unless $file;
die $usage unless $outfile;
die $usage unless $bed;
die $usage unless $depth;
die $usage unless $Rscript;
die $usage unless $bedtools;
$type ||= "CG";

my @mode=split(/\,/,$type);
foreach my $m(@mode){
	my (@bedgraph,@sample,@group);
	print "Reading map file...\n";
	open FILE, $file or die "can not open $file:$!";
	while(<FILE>){   
		chomp $_;
		next if(/^#Group/);
		my @sampleinfo=split(/\t/,$_);
		print "$sampleinfo[0]\t$sampleinfo[1]\n";
		my $in="$bed\/$sampleinfo[1]\/$sampleinfo[1]\_$depth"."x"."$m\.bedgraph";
		push @bedgraph,$in;
		push @sample,$sampleinfo[1];
		push @group,$sampleinfo[0];
	}
	close FILE;

	my $c=join(",", @bedgraph);
	my $s=join(",", @sample);
	my $s_head=join("\t","Sample",@sample);
	my $g_head=join("\t","Group",@group);

	print "Making $depth x $m  methylation matrix file...\n";
	system("date");
	my $mC="$outfile\/m$m";
	system("mkdir -p $mC");
	my $oc="$mC\/$depth"."x"."$m\.methy\_Matrix.txt";
	print "[COMMAND]: perl $p1 --in $c --head $s --out $oc -b $bedtools\n";
	system("perl $p1 --in $c --head $s --out $oc -b $bedtools");
	system("date");
	print "$m methylation stacked barplot for all samples...\n";
	my $oc_plot="$mC\/$depth"."x"."$m\.methy\_Matrix.forplot";
	system("perl -alne \'if\(\$.==1\)\{print \"$g_head\\n$s_head\";next\};print\' $oc \> $oc_plot");
	system("$Rscript $p2 $oc_plot 5 $mC/all_samples.$depth\X$m");
}

###########################################################################################################################
