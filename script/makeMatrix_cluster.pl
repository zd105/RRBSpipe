#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Spec;
use List::Util qw/sum min max/;
use File::Temp qw/tempfile tempdir/;
use File::Basename;
use FindBin qw($Bin $Script);
# -----------------------------------------------------------------------------
# Variables

my ($USAGE, $call, $ret, $help);
my ($in1, $class, $out, $pcc, $pca, $clust, $Rscript);
my ($r_pcc, $r_pca, $r_clust1, $r_clust2);
my $SCRIPTNAME = basename($0);

# -----------------------------------------------------------------------------
# OPTIONS


## R executable! checking of ALL flags

$USAGE = << "USE";
    
    synopsis: 
	
    usage:  perl $SCRIPTNAME --in <list> [--out <string>] --head <string> [-b <path/prefix>]

    [INPUT]     --in       input file of methyl-matrix file (the output of p01.input.pl);
                --class    inout file containing subclass identifiers for each sample(one per line), just used in PCA analysis.
                --pcc      run pearson correlation analysis
                --pca      run PCA (Principal Component Analysis) analysis
                --clust    run Clustering Analysis
                --out      prefix of output
                --r        path/executable of Rscript executable (default: in PATH)

    

USE

if (!@ARGV) {
    printf STDERR $USAGE;
    exit -1;
}

unless (GetOptions(
    "in=s" => \$in1,
    "out=s" => \$out,
    "pcc"  => \$pcc,
    "pca"   => \$pca,
    "clust" => \$clust,
    "class=s" =>\$class,
    "r=s"  => \$Rscript,
    "h|help"=> \$help
)){
    printf STDERR $USAGE;
    exit -1;
}

if (defined $help){
    printf STDERR $USAGE;
    exit -1;
}

# -----------------------------------------------------------------------------
# MAIN

my $cur_dir = File::Spec->curdir();

############
## checks ##
############
print STDERR ("[INFO]" . prettyTime() . "Checking options\n");

### input
unless( -e $in1){
	print STDERR "[Err]: the -in $in1 does not exists!\n";
	die $USAGE;
}

### out
if (defined $out){
    $out = File::Spec->rel2abs($out);
}
else {
    $out = ("pattern");
}

### script
$r_pcc = File::Spec->rel2abs("$Bin/PCC.R");
$r_pca = File::Spec->rel2abs("$Bin/PCA.R");
$r_clust1 = File::Spec->rel2abs("$Bin/HCLUST.R");
$r_clust2 = File::Spec->rel2abs("$Bin/PVCLUST.R");

### $Rscript
if (defined $Rscript){
    $Rscript = File::Spec->rel2abs($Rscript);
    if (-e $Rscript){
        unless (-d $Rscript){
            unless (-x $Rscript){
                die "##### AN ERROR has occurred: --r option executable is not executable\n";
            }
        }
        else{
            die "##### AN ERROR has occurred: --r option executable is directory\n";
        }
    }
    else{
        die "##### AN ERROR has occurred: --r option executable nonexistent\n";
    }
}
else{
    $Rscript = "Rscript";
}

$call = "command -v $Rscript &> /dev/null";
$ret = system ($call);
if ($ret != 0){
    die "##### AN ERROR has occurred: No bedtools executable found. Please provide path/filename of bedtools executable with --bedtools option\n";
}

#####################
## analysi and plot #
#####################
print STDERR ("[INFO]" . prettyTime() . "Begin to analysis ..\n");

if(defined $pcc && -e $r_pcc){
      $call = "$Rscript $r_pcc $in1 $out.PCC";
      call($call);
      print STDERR ("[INFO]: PCC analysis is done..\n");
}

if(defined $pca && -e $r_pca && -e $class){
	my $classfile = File::Spec->rel2abs($class);
	$call = "$Rscript $r_pca $in1 $classfile $out.PCA";
	call($call);
	print STDERR ("[INFO]: PCA analysis is done..\n");
}

if(defined $clust && -e $r_clust1){
	$call = "$Rscript $r_clust1 $in1 $out.hclust \&\& $Rscript $r_clust2 $in1 $out.pvclust.pdf";
	call($call);
	print STDERR ("[INFO]: Clustering analysis is done..\n");
}


# -----------------------------------------------------------------------------
# FUNCTIONS

sub call{
    my ($sub_call) = @_;
        
    $ret = system ($sub_call);
    
    if ($ret != 0){
        die "##### AN ERROR has occurred\n";
    }
}

sub prettyTime{
    my @months      = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @weekDays    = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
    my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
    my $year        = 1900 + $yearOffset;
    return "\t$weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $hour:$minute:$second, $year\t";
}

## END
