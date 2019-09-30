#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);

my $usage=<<"USAGE";
name:    $0

usage:   perl $0
	     
         ############ General parameters ##########################

         -list  <file>    file containing the sample names and data path you want 
                          this perl to do DMR analysis. Format of this file is :
                          "samplename\\tgroupname\\tinput.bedgragph"; 
         -metilene <str>  metilene path(metilene_v0.2-6/ abs dir )
         -outdir  <str>   output dir (default: .)
         -name    <str>   prefix of outputname (default: dmr)     

         ############  DMR detection ##########################

         -bedtools  <str>   the path/executable of bedtools executable
         -Rscript <str> Rscript program;
         -max  <int>    maximum distance (default:300)
         -min  <int>    minimum cpgs (default:10)
         -d  <flt>    minimum mean methylation difference (default:0.100000)
         -t  <int>    number of threads (default:1)
         -f  <int>    number of method: 1: de-novo, 2: pre-defined regions
         -B  <str>    bed-file for mode 2 containing pre-defined regions; 
                      needs to be SORTED equally to the DataInputFile (default:none)
         -groupA   <str>  name of group A (default: the group name read first time in -list)
         -groupB   <str>  name of group B (default: the group name read second time in -list)
         -X  <int>    minimal number of values in group A (default:-1)
         -Y  <int>    minimal number of values in group B (default:-1)
         -v  <int>    valley filter (0.0 - 1.0) (default:0.700000)

         ########### DMR filtering and stat ################################

         -p  <flt>    use maximum (<) Mann-Whitney-U test p-value for output of significant DMRs (default: 0.05)
         -q  <flt>    use maximum (<) adj. p-value (q-value) for output of significant DMRs (default: 0.05)
         -c  <int>    minimum (>=) cpgs (default:10)       
         -l  <int>    minimum length of DMR [nt] (>=) (default: 0, means no filtering)
         -r  <flt>    minimum mean methylation difference (>=) (default:0.1)        

         -help|?|h

author:  luhanlin.hi\@gmail.com
date:
USAGE

my ( $LIST, $OUTDIR, $PREFIX, $bedtools, $M, $m, $d, $t, $f, $B, 
        $groupA, $groupB, $X, $Y, $v, $p, $q, $c, $l, $r, $HELP,$softdir,$Rscript);

GetOptions(
    "list=s"        => \$LIST,
    "outdir:s"      => \$OUTDIR,
    "name:s"        => \$PREFIX,
    "metilene:s"    => \$softdir,
    "bedtools:s"    => \$bedtools,
	"Rscript:s"    => \$Rscript,
    "max:i"           => \$M,
    "min:i"           => \$m,
    "d:f"           => \$d,
    "t:i"           => \$t,
    "f:i"           => \$f,
    "B:s"           => \$B,
    "groupA:s"      => \$groupA,
    "groupB:s"      => \$groupB,
    "X:i"           => \$X,
    "Y:i"           => \$Y,
    "v:f"           => \$v,
	"q:f"           => \$q,
    "p:f"           => \$p,
    "c:i"           => \$c,
    "l:i"           => \$l,
    "r:f"           => \$r, 
    "h|?|help"      => \$HELP
);

die $usage if $HELP;
die $usage unless $LIST;
die $usage unless $bedtools;
die $usage unless $softdir;
die $usage unless $Rscript;

my $perl01 = "$softdir/metilene_input.pl";
my $metilene = "$softdir/metilene";
my $perl02 = "$Bin/metilene_output.v_q-value_filter.pl";
my $perl03 = "$Bin/metilene_output.v_p-value_filter.pl";

$OUTDIR ||= ".";
$PREFIX ||= "dmr";
$M ||= 300;
$m ||= 10;
$d ||= 0.1;
$t ||= 4;
$f ||= 1;
$B ||= "";
$X ||= -1;
$Y ||= -1;
$v ||= 0.7;
if(!$p){$q ||=0.05};
if(!$q){$p ||=0.05};
$c ||= 10;
$r ||= 0.1;
$l ||= 0;


print STDERR "[run]: reading samplelist -> $LIST ..\n";
my %group = ();
my @group_in_order = ();
open IN, $LIST or die "[err]: can not open file: $LIST\n";
while(<IN>){
	chomp;
	next if /^#/;
	next if /^\s*$/;
	my ($samplename, $groupname, $file) = split;
	push @group_in_order, $groupname unless exists $group{$groupname};
	$group{ $groupname }{ $samplename } = $file;
}
close IN;

foreach (@group_in_order){print "#### -> $_\n";}

die "[err]:the second group doesn't exists!\n" unless scalar @group_in_order >= 2;
$groupA ||= $group_in_order[0];
$groupB ||= $group_in_order[1];

##### data processing
my @bedA = ();
my @bedB = ();
foreach my $sam (keys %{ $group{ $groupA } }){
	my $bedfile = $group{$groupA}{$sam};
        if(-e $bedfile){
			push @bedA, $bedfile;
        }else{
			print STDERR "[err]: file not exists -> $bedfile\n";
		}
}

foreach my $sam (keys %{ $group{ $groupB } }){
	my $bedfile = $group{$groupB}{$sam};
        if(-e $bedfile){
            push @bedB, $bedfile;
        }else{
			print STDERR "[err]: file not exists -> $bedfile\n";
		}
}

my $bedA_list = join(",", @bedA);
my $bedB_list = join(",", @bedB);
print STDERR "[run]: get metilene input file -> $OUTDIR/$PREFIX.input\n";
print STDERR "[command]: perl $perl01 --in1 $bedA_list --in2 $bedB_list --out $OUTDIR/$PREFIX.input --h1 $groupA --h2 $groupB -b $bedtools\n";

system("perl $perl01 --in1 $bedA_list --in2 $bedB_list --out $OUTDIR/$PREFIX.input --h1 $groupA --h2 $groupB -b $bedtools");

print STDERR "[done]: get metilene input file -> $OUTDIR/$PREFIX.input\n";

##### DMR detection
print STDERR "[run]: DMR detection between: group $groupA and group $groupB\n";

if(-e $B && $f==1){
	print STDERR "[infor]: you have set the -B is $B, and -f is 1, so here -f will be set as 2 !\n";
        $f = 2;
}

if($f==1){
    print STDERR "[command]: $metilene -M $M -m $m -d $d -t $t -f $f -a $groupA -b $groupB -X $X -Y $Y -v $v $OUTDIR/$PREFIX.input 2> $OUTDIR/$PREFIX.metilene.log |sort -k1,1 -k2,2g > $OUTDIR/$PREFIX.dmr.xls\n";
    system("$metilene -M $M -m $m -d $d -t $t -f $f -a $groupA -b $groupB -X $X -Y $Y -v $v $OUTDIR/$PREFIX.input 2> $OUTDIR/$PREFIX.metilene.log |sort -k1,1 -k2,2g > $OUTDIR/$PREFIX.dmr.xls");
}
elsif($f==2){
    if(-e $B){
        print STDERR "[command]: $metilene -M $M -m $m -d $d -t $t -f $f -B $B -a $groupA -b $groupB -X $X -Y $Y -v $v $OUTDIR/$PREFIX.input 2> $OUTDIR/$PREFIX.metilene.log |sort -k1,1 -k2,2g > $OUTDIR/$PREFIX.dmr.xls\n";
        system("$metilene -M $M -m $m -d $d -t $t -f $f -B $B -a $groupA -b $groupB -X $X -Y $Y -v $v $OUTDIR/$PREFIX.input 2> $OUTDIR/$PREFIX.metilene.log |sort -k1,1 -k2,2g > $OUTDIR/$PREFIX.dmr.xls");
    }
    else{
        die "[err]: if -f is 2, you must default the bed-file for mode 2 containing pre-defined regions\n";
    }
}

##### filtering 
if($p){
    #use p-value to filter
	print STDERR "[run]: DMR filtering by p-value..\n   [command]: filtering -> perl $perl03 -q $OUTDIR/$PREFIX.dmr.xls -o $OUTDIR/$PREFIX.dmr.filter -p $p -c $c -d $r -l $l -a $groupA -b $groupB -Rscript $Rscript\n";
	system("perl $perl03 -i $OUTDIR/$PREFIX.dmr.xls -o $OUTDIR/$PREFIX.dmr.filter -p $p -c $c -d $r -l $l -a $groupA -b $groupB -Rscript $Rscript");
	system("mv $OUTDIR/$PREFIX.dmr.filter\_pval.$p.out $OUTDIR/$PREFIX.dmr.filter\_pval.$p.out.xls");
	system("sed -i \'1i\#Chr\tStart\tEnd\tP-value\tDifference\t\#CpGs\t$groupA\t$groupB\' $OUTDIR\/$PREFIX.dmr.filter\_pval.$p.out.xls");
}else{
	#use q-value to filter
	print STDERR "[run]: DMR filtering by q-value..\n   [command]: filtering -> perl $perl02 -q $OUTDIR/$PREFIX.dmr.xls -o $OUTDIR/$PREFIX.dmr.filter -q $q -c $c -d $r -l $l -a $groupA -b $groupB -Rscript $Rscript\n";
	system("perl $perl02 -i $OUTDIR/$PREFIX.dmr.xls -o $OUTDIR/$PREFIX.dmr.filter -q $q -c $c -d $r -l $l -a $groupA -b $groupB -Rscript $Rscript");
	system("mv $OUTDIR/$PREFIX.dmr.filter\_qval.$q.out $OUTDIR/$PREFIX.dmr.filter\_qval.$q.out.xls");
	system("sed -i \'1i\#Chr\tStart\tEnd\tQ-value\tDifference\t\#CpGs\t$groupA\t$groupB\' $OUTDIR\/$PREFIX.dmr.filter\_qval.$q.out.xls");
}

system("sed -i \'1i\#Chr\tStart\tEnd\tQ-value\tDifference\t\#CpGs\tp\(MWU\)\tp\(2D KS\)\t$groupA\t$groupB\' $OUTDIR\/$PREFIX.dmr.xls");

print STDERR "[ok] DMR detection is done..\n";
