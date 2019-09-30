#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use PerlIO::gzip;
my $usage = <<USAGE;
Usage : perl $0

                    -D  [input_1: in.fa or in.fa.gz
                         default : "/public/agis/gaofei_group/luhanlin/02_data/hg19/fa/hg19.fa";]
                    -R  <input_2: region.bed>
                    -f  [input_2_format:
                                chrID-start-end [0-1-2] 
                                regionID-chrID-start-end [3-0-1-2]
                                regionID-chrID-start-end-strand [3-0-1-2-5] ]
                    -O  [output: region.fa [out.fa] ]
                    -T  [sequence in output is continuous ]
                    -N  [number of bases per line in output.[50] ]

example: perl $0 -D refrence.fa -R region.bed -f 0-1-2-3 -O region.fa
USAGE

my ($ref, $reg, $out, $format, $One, $baseN);

GetOptions (
    "D:s" => \$ref,
    "R=s" => \$reg,
    "O:s" => \$out,
    "f:s" => \$format,
    "T"   => \$One,
    "N:i" => \$baseN
);

die $usage unless ($reg);

################################################################################
######################                                   ########################
#################################################################################
$ref ||= "/public/agis/gaofei_group/luhanlin/02_data/hg19/fa/hg19.fa";
$out ||= "out.fa";
$format ||= "0-1-2";
$baseN ||= 50;

my ($regionID_c, $chr_c, $start_c, $end_c, $strand_c);
my @f = split("-", $format);
if(@f==3){
    ($chr_c, $start_c, $end_c) = @f;
}
elsif(@f==4){
    ($regionID_c, $chr_c, $start_c, $end_c) = @f;
}
elsif(@f==5){
    ($regionID_c, $chr_c, $start_c, $end_c, $strand_c) = @f;
}
else{
    print STDERR "Incorrect parameter: -f\n";
    die $usage;
}

print STDERR "|--> Reading the Ref : $ref\n";
if($ref=~m/\.gz$/){
    open IN,"<:gzip", "$ref" or die "cannot open the reference file:\t$ref\n";
}
else{
    open IN, "<$ref" or die "cannot open the reference file:\t$ref\n";
}
my %ref;
my $chr;       

while (<IN>) {
    chomp;
    if (/>(\S+)/) {
        $chr = $1;
    }
    else{
        $ref{$chr} .= $_;
    }
}
close IN;

open IN, "$reg" or die "cannot open the region file:\t$reg\n";

open OUT, ">$out" or die $!;

print STDERR "|--> Extract the sequence ...\n";

while (<IN>){
    chomp;
    next if /^\s*$/;
    my @arr = split(/\s+/, $_);
    my ($chr, $start, $end) = @arr[$chr_c, $start_c, $end_c];
    my $regionID = $regionID_c ? $arr[$regionID_c] : "R$.";
    my $strand = $strand_c ? $arr[$strand_c] : "+"; 
    my $seq = substr($ref{$chr}, $start-1, $end - $start + 1);
    print OUT ">$regionID:$chr:$start-$end:$strand\n";
    if($strand eq "-"){
        $seq =~tr/ACGTacgt/TGCAtgca/;
	        $seq = join("", reverse( split( //, $seq) ) )."\n";
    }
    unless(defined $One){
        my $i=0;
        while ( $i < length($seq) - $baseN ) {
            print OUT substr($seq, $i, $baseN),"\n";
            $i += $baseN;
        }
        print OUT substr($seq, $i, ), "\n";
    }
    else{
        print OUT "$seq\n";
    }
}
close IN;
close OUT;
print STDERR "|--> All done ...\n";

