#!usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
#use FindBin qw($Bin $Script);
#use File::Basename qw(basename dirname);
#use Cwd;
#use PerlIO::gzip;
my $usage=<<"USAGE";
name:    $0
usage:   perl $0 *.fa
         Input : fasta files
         ouput :
         Seq_ID  Len  C_#  G_#  [C+G]_#  CpG_#  (G+C)%  OE
author:  luhanlin\@genomics.org.cn
date:
USAGE
die $usage unless $ARGV[0];
open (IN,"<","$ARGV[0]") || die "can't open $ARGV[0]";
my ($name, $sequence);
print "Seq_ID\tLen\tC_#\tG_#\t[C+G]_#\tCpG_#\t(G+C)%\tOE\n";
while(<IN>){
    chomp;
    if(/^>(\S+)/){
        if($. > 1){
            CG_detect($name,$sequence);
        }
        $name = $1;
        $sequence = "";
    }
    else{
        $sequence .= $_;
    }
}
CG_detect($name, $sequence);
close IN;
####
sub CG_detect{
    my ($id, $str) = @_;
    my ($c,$g,$cg,$oe,$gc,$tgc,$len) = (0,0,0,0,0,0,0);
    $c  = ($str=~s/c/c/gi);
    $g  = ($str=~s/g/g/gi);
    $cg = ($str=~s/cg/cg/gi);
    $gc = $c + $g;
    $len = length($str);
    $tgc = $len==0 ? 0 : $gc/$len;
    $cg  = $cg ? $cg : 0;
    $c   = $c ? $c : 0;
    $g   = $g ? $g : 0;
    $gc  = $gc ? $gc : 0;
    if($c && $g){
        $oe = $len==0 ? 0 : $cg*$len/($c*$g);
    }
    else{
        $oe=0;
    }
    $tgc = sprintf("%.4f", $tgc);
    $oe = sprintf("%.4f", $oe);
    print "$id\t$len\t$c\t$g\t$gc\t$cg\t$tgc\t$oe\n";
}
