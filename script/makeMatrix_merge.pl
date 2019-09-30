#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Spec;
use List::Util qw/sum min max/;
use File::Temp qw/tempfile tempdir/;
use File::Basename;

# -----------------------------------------------------------------------------
# Variables

my ($USAGE, $call, $ret, $help);
my ($in1, $out, $h1, $l, $bedtools);
my ($NA, $out_metilene, $g1_h, $g1_n);
my (@g1, @g1_h);
my $order = "";
my $SCRIPTNAME = basename($0);

# -----------------------------------------------------------------------------
# OPTIONS


## R executable! checking of ALL flags

$USAGE = << "USE";
    
    synopsis: Combines multiple bedgraph input files of CpGs methylation levels INTO a single file [methyl matrix];
	
    usage:  perl $SCRIPTNAME --in <list> [--out <string>] --head <string> [-b <path/prefix>]

    [INPUT]     --in       comma-seperated list of sorted (!) bedgraph input files of CpGs methylation levels
                --head     comma-seperated list of identifier for bedgraph input files (default: numeric)
                --out      path/file of out file (default: ./methyl_matrix.txt)
                -b         path/executable of bedtools executable (default: in PATH)

    

USE

if (!@ARGV) {
    printf STDERR $USAGE;
    exit -1;
}

unless (GetOptions(
    "in=s" => \$in1,
    "out=s" => \$out,
    "head=s"  => \$h1,
    "b=s"   => \$bedtools,
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
print STDERR ("[WARNING]" . prettyTime() . "Input files need to be SORTED, i.e., use \"bedtools sort -i file >file.sorted\"\n");
print STDERR ("[INFO]" . prettyTime() . "Checking flags\n");

$NA = "NA";

if (defined $in1){
    @g1 = split(/,/,$in1);
    
    for (my $i=0; $i<scalar(@g1); $i++){
        $g1[$i] = File::Spec->rel2abs($g1[$i]);
        
        if ((defined $g1[$i]) && (-e $g1[$i])){
            unless (-r $g1[$i]){
                die "##### AN ERROR has occurred: $g1[$i] (option --g1) not readable\n";
            }
        }
        else{
            die "##### AN ERROR has occurred: required option --g1 ($g1[$i]) missing or nonexistent\n";
        }
    }
}
else {
    die "##### AN ERROR has occurred: required option --$in1 missing\n";
}

if (defined $h1){
	@g1_h = split(/,/,$h1);
	unless(@g1_h == @g1){
		die "##### AN ERROR has occurred: the number of identifier for bedgraph input files is not equal to the number of bedgraph input files!\n";
	}
}
else{
	print STDERR "[Warning]: undefined option --head, automatic numbering will be used..\n";
	for (my $i=0; $i<scalar(@g1); $i++){
		$g1_h[$i] = "file_$i";
	}
}

if (defined $out){
    $out            = File::Spec->rel2abs($out);
    $out_metilene   = $out;
}
else {
    $out_metilene   = ("methyl_matrix.txt");
}

## bedtools ##
if (defined $bedtools){
    $bedtools = File::Spec->rel2abs($bedtools);
    if (-e $bedtools){
        unless (-d $bedtools){
            unless (-x $bedtools){
                die "##### AN ERROR has occurred: --bedtools option executable is not executable\n";
            }
        }
        else{
            die "##### AN ERROR has occurred: --bedtools option executable is directory\n";
        }
    }
    else{
        die "##### AN ERROR has occurred: --bedtools option executable nonexistent\n";
    }
}
else{
    $bedtools = "bedtools";
}
$call = "command -v $bedtools &> /dev/null";
$ret = system ($call);
if ($ret != 0){
    die "##### AN ERROR has occurred: No bedtools executable found. Please provide path/filename of bedtools executable with --bedtools option\n";
}

#####################
## union bedgraph ##
####################
print STDERR ("[INFO]" . prettyTime() . "Write metilene input to $out_metilene\n");

$g1_n = join(" ", @g1);
$g1_h = join(" ", @g1_h);

$call = "$bedtools unionbedg -header -names $g1_h -filler $NA -i $g1_n | cut -f1,2,4- | sed '/\tNA/d; s/\t/:/' | sed 's/chrom:start//' >$out_metilene";

call($call);

print STDERR ("[NEXT STEP]: The For further parameters: makeMatrix_cluster.pl --help\n");

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
