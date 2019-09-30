#!/usr/bin/perl
use strict;
use Getopt::Long;
use Cwd 'abs_path';
my $usage=<<"USAGE";
  
 name:    EAGE_function
            
            It is designed for gene list GO and KEGG function analysis by EAGE program.
 version:1.0
 usage:   perl $0
            -i <str>  input gene symbol list;
            -s <str>  specify the species names, default is hsa;
                      optional:
                        hsa : human
                        mmu : mouse
                        ssc : pig
                        csv : Cucumis sativus (cucumber)
                        ath : Arabidopsis thaliana (thale cress)
                        mcc : Macaca mulatta (rhesus monkey)
                        rro : Rhinopithecus roxellana (golden snub-nosed monkey)
            -q <str>  q-value cut off; default is 0.05;
            -o <str>  results file path;
            -eage <str>  EAGE program abs dir;
            -h <str>  help;
 author:  zhangdu
 date: 2017-03-20
USAGE

my ($infile,$outdir,$species,$q_val,$EAGE);
my $help;
GetOptions("i=s"       =>  \$infile,
           "s=s"       => \$species,
		   "o=s"       => \$outdir,
		   "q=s"     => \$q_val,
		   "eage=s"     => \$EAGE,
           "h=s"       => \$help
		   );

die $usage if $help;
die $usage unless $infile;
die $usage unless $outdir;
die $usage unless $species;
die $usage unless $EAGE;
$q_val ||=0.05;

my @a=split(/\//,$infile);
my $outdir1="$outdir\/Q$q_val";
system("mkdir -p $outdir1");
system("cp $infile $outdir");
my $outp="$outdir1\/$a[-1]";

# GO enrichment
print "================ GO enrichment analysis ======================\n";
print "GO function analysing...\n";
system("perl $EAGE/EAGE.pl -L $infile -S $species -O $outp.GO -A BH -C $q_val");

# KEGG enrichment
print "================ KEGG enrichment analysis ======================\n";
print "KEGG function analysing...\n";
system("perl $EAGE/EAGE.pl -L $infile -T kegg -S $species -O $outp.KEGG -A BH -C $q_val");

# plot
print "================ Barplot and bubble polt ======================\n";
print "[run] perl $EAGE/EAGE_plot.pl -i $outp.GO.xls -t GO -n 2 -f 2 -q $q_val -o $outp.GO\n";
system("perl $EAGE/EAGE_plot.pl -i $outp.GO.xls -t GO -n 2 -f 2 -q $q_val -o $outp.GO");
print "[run] perl $EAGE/EAGE_plot.pl -i $outp.KEGG.xls -t KEGG -n 2 -f 2 -q $q_val -o $outp.KEGG\n";
system("perl $EAGE/EAGE_plot.pl -i $outp.KEGG.xls -t KEGG -n 2 -f 2 -q $q_val -o $outp.KEGG");

print "================ GO and KEGG enrichment finished ======================\n";
