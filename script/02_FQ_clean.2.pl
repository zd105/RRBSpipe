#!/usr/bin/perl
#       AUTHOR:  luhanlin@genomics.org.cn
#      COMPANY:  BGI
#      VERSION:  1.0
#      CREATED:  05/06/2010 05:17:07 PM
use strict;
use warnings;
use PerlIO::gzip;
die "Usage: perl $0 in.fq out.prefix \n" unless @ARGV==2;

my ($fq, $out) = @ARGV;
my $in;
if ($fq=~/\.gz$/){
    open $in, "<:gzip","$fq" or die "$! --> $fq\n";
}
else{
    open $in, "<$fq" or die "$! --> $fq\n";
}

open OA, ">:gzip", "$out.1.fq.gz" or die $!;
open OB, ">:gzip", "$out.2.fq.gz" or die $!;
open OC, ">:gzip", "$out.single.fq.gz" or die $!;
##########

my $flag = 0;
my @pair = ();
my ($f1, $f2, $psum, $ssum);
print STDERR "Check and Clean begin..\n";
while(1){
    if($flag==0){
        $pair[0] = readin($in);
        $pair[1] = readin($in);
        $flag = 2;
    }
    elsif($flag==1){
        $pair[1] = readin($in);
        $flag = 2;
    }
    last unless $pair[0] && $pair[1];

    ###print STDERR $pair[0] . $pair[1];
    if( paired(\@pair) ){
        $f1 = check($pair[0]);
        $f2 = check($pair[1]);
        $flag = 0;
        if($f1 && $f2){
            $psum += 1;
            print OA $pair[0];
            print OB $pair[1];
        }
        elsif($f1){
            $ssum += 1;
            print OC $pair[0];
        }
        elsif($f2){
            $ssum += 1;
            print OC $pair[1];
        }
    }
    else{
        $flag = 1;
        $f1 = check($pair[0]);
        if($f1){
            $ssum += 1;
            print OC $pair[0];
        }
        shift @pair;
    }
}
if($pair[0]){
    $f1 = check($pair[0]);
    print OC $pair[0] if $f1;
}
print STDERR "Check and Clean done..\n";
print STDERR "Paired reads(p)\tsingle(s)\n";
print STDERR "$psum * 2\t$ssum\n";

close $in;
close OA;
close OB;
close OC;


sub paired{
    my $arr = shift;
    my $id1 = ( split(/\n/, $$arr[0]) )[0];
    my $id2 = ( split(/\n/, $$arr[1]) )[0];
    my $r1 = substr($id1, 2, 9);
    my $r2 = substr($id2, 2, 9);
    if($id1=~/:1$/ && $id2=~/:2$/ && $r1 eq $r2){
        return 1;
    }
    else{
        return 0;
    }
}

sub readin{
    my $fh = shift;
    my $id = <$fh>;
    if($id){
        my $r = <$fh>;
        my $s = <$fh>;
        my $q = <$fh>;
        return( $id.$r.$s.$q );
    }
    else{
        return("");
    }
}

sub check{
    my $l = shift;
    my ($line1, $line2, $line3, $line4) = split(/\n/, $l);

    my @arr = split(//, $line2);
    my $i=0;
    for(my $j=0; $j<@arr; $j++){
        if($arr[$j] eq 'N'){
            $i = $i+1;
        }
    }
    my $percent1 = $i/@arr;
    my @arr1 = split(//, $line4);
    my $k=0;
    for(my $m=0; $m<@arr1; $m++){
        if( ord($arr1[$m])-33 <= 5 ){
        $k = $k+1;
        }
    }
    my $percent2 = $k/@arr1;
    if($percent1 >= 0.1 || $percent2 >= 0.5){
        return 0;
    }
    else{
        return 1;
    }
}
