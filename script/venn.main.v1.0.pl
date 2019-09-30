#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
use Cwd;
use PerlIO::gzip;
#~~~~~~~~      USAGE      ~~~~~~~~#
my $usage=<<"USAGE";
name:    $0
usage:   perl $0
              -I <>      list1
                      or list1,list2
                      or list1,list2,list3
                      or list1,list2,list3,list4
                      or list1,list2,list3,list4,list5
                      list[1..5] is a input file containing one column (e.g., integers, chars),
                      with each component corresponding to a separate circle in the Venn diagram
              -N []   name1,name2,..name5
              -Rscript [] Rscript program 
              -O []   out prefix
              -h []   help
author:  zhangdu
date:
USAGE
#~~~~~~~~  Globle Parameters  ~~~~~~~~#
my ($filelist, $namelist, $out, $help,$Rscript);
GetOptions(
    "help|?|h" => \$help,
    "I=s"      => \$filelist,
    "N:s"      => \$namelist,
    "Rscript:s"      => \$Rscript,
    "O:s"      => \$out,
);
die $usage if $help;
die $usage unless ($filelist);
die $usage unless ($namelist);
die $usage unless $Rscript;
$out ||= "venn";

#~~~~~~~~~   Main Process     ~~~~~~~~#
my @collist;
my @flist = split(/,/, $filelist);
for (my $i=0; $i<=$#flist; $i++){
	push @collist, 0;
}
my $clist=join(",",@collist);

system("perl $Bin\/Venn.pl -I $filelist -C $clist \> $out.venn.xls");
system("perl $Bin\/Draw_venn.pl -I $filelist -N $namelist -Rscript $Rscript -O $out.venn.pdf");

