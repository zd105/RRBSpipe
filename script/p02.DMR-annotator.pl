#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin $Script);
use PerlIO::gzip;
my $usage=<<"USAGE";
name:    $0
usage:   perl $0
         
         This perl is used to annotate the DMR into genomic elements (including promoter, CGI or any one you gave).
             -DMR   DMR file (bed format);
                      chr1    start    end   ... 
             -annot list of annotation infomation file (bed format);
                    #example for list file: 
                      promoter    path/promoter.bed
                      CGI         path/CGI.bed
                      5utr        path/5utr.bed
                      exon        path/exon.bed
                    #format of promoter.bed :
                      chr1    start    end    ID    annotation    +
          -help
example : perl $0 -DMR in.dmr -annot annot.list > in.dmr.annt.txt
author:  luhanlin\@genomics.org.cn
date:
USAGE

my ($dmrfile, $annotlist, $help);

GetOptions (
    "DMR=s" => \$dmrfile,
    "annot=s" => \$annotlist,
    "help"       => \$help,
);

die $usage if $help;
die $usage unless $dmrfile && $annotlist;

my $getoverlap = "$Bin/disposeOverlap.pl";

#
print STDERR "|-- reading DMR file: $dmrfile ..\n";
my $tmp = "tmp.dmr.txt";
# my @head = ();
open DMR, $dmrfile or die $!;
open OUT, "> $tmp" or die $!;
while(<DMR>){
	chomp;
	if(/^#/){
            next;
	}
	else{
	    my $dmrID = "DMR$.";
	    print OUT "$dmrID\t$_\n";
	    # @head = split(/\t/, $_);
        }
}
close DMR;
close OUT;

#
my %res = ();
my @list = ();
print STDERR "|-- reading annotation file list ..\n";
open IN, $annotlist or die $!;
while(<IN>){
	chomp;
	my @aa = split(/\t/, $_);
	my $name = $aa[0];
	push @list, $name;
	my $file = $aa[1];
	my $output = "tmp.$name.overlap";

        print STDERR "|-- overlap with ELEMENT: $name, \n\tfile: $file, \n\toutput: $output ..\n";
	system("$getoverlap --i1 $tmp --f1 1-0-2-3 --i2 $file --f2 0-4-1-2 --OL 0.5-small --mN 1 --E O > $output");

	print STDERR "|-- parse output: $output ..\n";
	open IB, "$output" or die $!;
	while(<IB>){
		chomp;
		next if $.==1;
		my @bb = split;
		my $dmrid = $bb[1];
		my %u = ();
		foreach my $ele (@bb[8..$#bb]){
			my $id = (split(/:/, $ele))[0];
			$u{$id} += 1;
		}
		my $annot_id = join(",", keys %u);
		$res{$dmrid}{$name} = $annot_id;
	}
	close IB;

        print STDERR "|-- remove output: $output ..\n";
	system("rm -f $output");

}
close IN;

#
print STDERR "|-- write the result ..\n";
open IA, $tmp or die $!;
print join("\t", "chr", "start", "end", "q-value", "methyl-diff", "CpGs", "methyl_a", "methyl_b", @list), "\n";
while(<IA>){
	chomp;
	my @aa = split(/\t/, $_);
	my $dmrid = $aa[0];
	my @out = ();
	foreach my $name (@list){
		my $o = $res{$dmrid}{$name} ? $res{$dmrid}{$name} : "--";
		push @out, $o;
	}
	print join("\t", @aa[1..$#aa], @out), "\n";
}
close IA;

system("rm -f $tmp");
print STDERR "|-- program is done .. \n\n\n";

# END
