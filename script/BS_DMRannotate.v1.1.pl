#!/usr/bin/perl
use strict;
use Getopt::Long;
use FindBin qw($Bin $Script);
use Cwd 'abs_path';
my $usage=<<"USAGE";
  
 name:    BS_DMRannotate
            
            It is designed for DMR annotation of  BS-seq.
 version:1.1
 usage:   perl $0
            -i <str>  "*.dmr.filter_qval.0.05.out" file from DMR detection; 

            -a <str>  assign a annotation list file; or do not set this by use the script to generate a default annotation list; 
                      the format of annotation list is like(default):

                      up2k     \$Pj_path/04_global_methy/03_element_methy/element/genome.up2k.bed
                      down2k   \$Pj_path/04_global_methy/03_element_methy/element/genome.down2k.bed
                      promoter \$Pj_path/04_global_methy/03_element_methy/element/genome.promoter.bed
                      genebody \$Pj_path/04_global_methy/03_element_methy/element/genome.genebody.bed
                      intron   \$Pj_path/04_global_methy/03_element_methy/element/genome.intron.bed
                      exon     \$Pj_path/04_global_methy/03_element_methy/element/genome.exon.bed
                      cgi      \$Pj_path/04_global_methy/03_element_methy/element/genome.cgi.bed
                      
                      format of .bed files:
                      chr1    start    end    ID    annotation    +

            -p <str>  project path;
            -o <str>  annotation results file path;
            -ele  <str>  the annotated element gene list you want; default: "promoter,genebody";
            -h <str>  help;
 author:  zhangdu
 date: 2017-03-20
USAGE

my $p1="$Bin/p02.DMR-annotator.pl";


my ($file,$outdir,$annolist,$element,$pro);
my $help;
GetOptions("i=s"       =>  \$file,
           "a=s"       => \$annolist,
		   "o=s"       => \$outdir,
		   "ele=s"     => \$element,
		   "p=s"     => \$pro,
           "h=s"       => \$help
		   );

die $usage if $help;
die $usage unless $file;
die $usage unless $outdir;
#die $usage if(!($annolist && $pro));
print("You are using a default annotation list file, which will annotate DMRs to the following elements:
########################
##### upstream2k   #####
##### downstream2k #####
##### promoter     #####
##### exon         #####
##### intron       #####
##### genebody     #####
##### cgi          #####
########################
") unless $annolist;


system("mkdir -p $outdir");
my @dir=split(/\//,$file);
my $out="$outdir\/$dir[-1].annotate.xls";

if($annolist){
	open ANNO, $annolist or die "can not open $annolist:$!";
	while(<ANNO>){
		chomp $_;
		my @e=split(/\t/,$_);
		print "You will annotate DMRs to\: ###### $e[0] ######\n";
	}
	close ANNO;
	print "|------DMR annotation start...\n";
	system("perl $p1 -DMR $file -annot $annolist \> $out");
}else{
	my $default_annolist ="$outdir\/default.annolist";
	open DE, ">$default_annolist" or die "can not open $default_annolist:$!";
	print DE "up2k	$pro/03_global_methy/03_element_methy/element/genome.up2k.bed\n";
	print DE "down2k	$pro/03_global_methy/03_element_methy/element/genome.down2k.bed\n";
	print DE "promoter	$pro/03_global_methy/03_element_methy/element/genome.promoter.bed\n";
	print DE "genebody	$pro/03_global_methy/03_element_methy/element/genome.genebody.bed\n";
	print DE "intron	$pro/03_global_methy/03_element_methy/element/genome.intron.bed\n";
	print DE "exon	$pro/03_global_methy/03_element_methy/element/genome.exon.bed\n";
	print DE "cgi	$pro/03_global_methy/03_element_methy/element/genome.cgi.bed\n";
	close DE;
	print "|------DMR annotation start...\n";
	system("perl $p1 -DMR $file -annot $default_annolist \> $out");
}

my @elelist=split(/\,/,$element);
foreach my $e(@elelist){
	print "|------Output $e DMR gene list..\n";
	my $genelist = "$out.$e.genelist.txt";
	open AN, $out or die "can not open $out:$!";
	open LIST, ">$genelist" or die "can not open $genelist:$!";
	my $n;
	my $DMR_num=0;
	my $DMG_num=0;
	my %list;
	while(<AN>){
		chomp $_;
		my @F=split(/\t/,$_);
		if($.==1){
			while (my($id, $val) = each @F){
				if($val eq $e){
					$n = $id;
				}
			}
		print "======= In the $n th colum in annotate result file ============\n";
		}
		my @a=split(/\,/,$F[$n]);# PARD3|NM_001184785,PARD3|NM_001184792
		foreach my $i (@a){
			my @b=split(/\|/, $i); # PARD3|NM_001184785
			if($b[0] ne "--" && $b[0] ne $e ){
				#print LIST "$b[0]\n";
				#print "$i\n"  unless $b[0] eq "--";
				$DMR_num++;
				$list{$b[0]}=1;
			}
		}
	}
	# print uniq gene list
	while (my($key, $val) = each %list){
		print LIST "$key\n";
		$DMG_num++;
	}

	print "|------Total annotate $DMR_num DMR to $e region of $DMG_num genes...\n";
	close LIST;
	close AN;
}
print "|------Congratulations! DMR annotation finished!\n";



