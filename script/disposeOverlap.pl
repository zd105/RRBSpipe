#!/usr/bin/perl

=head1 Name

disposeOverlap.pl  --  dispose overlap relations between one or two block sets

=head1 Description

This program is designed to find overlap relations of blocks, the input files
can be one or two tables,  just need to point out the column of ID, Stand
and End;This script is modified from fanw's findOverlap.pl

The algorithm is that:
(1)Order: sort the two block sets based on start positions, seperately;
(2)Traversal: walk along the chromosome, and find out overlap between the twoblock sets.
(3)Output:
    (i)if you had chosen  "--C" option, the output table would list the regions gone
        through combining the overlapping, and use the outstretched one instead of
        all the regions each other staying with overlapping; and output all the regions
        without redundance

    (ii)if you had chosen "--E" option, the output table would report who and who
        overlapped, as well as their regions(start and end postition), their own size
        and the overlapped size, it is sourced from fanw's program;

        The output is TAB delimited with each line consisting of
        Col 1:ID
        COl 2~5:FirstTable: RegionID Start End Length
        Col 6:OverlapNumber
        Col 7:OverlapSize
        Col 8:OverlapRate
        Col 9~:SecondTable: RegionID:Start,End,Length,OverlapSize
        Col ...:if exists more than one overlapped region the format is the same as Col 4

    (iii)if you had chosen "--F" option, the output table would list all the regions
        which has been filtered out overlapping with others in a certain degree, just left
        the relatively uniq regions.

=head1 Version

  Author: BENM, binxiaofeng@gmail.com
  Version: 3.3,  Date: 2008-2-25 UpDate: 2009-01-28

=head1 Usage

  --i1 <str>					input the first table file
  --f1 <int-int-int>  || <int-int-int-int>	input the first table format [id-start-end] [id1-id2-start-end]
  --i2 <str>					input the second table file
  --f2 <int-int-int>  || <int-int-int-int>	input the second table format [id-start-end] [id1-id2-start-end]
  --OL <num-str>	set the overlapped limited condition, see below "PS", default: 0
  --final	Limit the final overlap limited conditions
  --mN <int>	set the minimuim overlapping number: [0] (only could be used in existing "--E" option
                in "--E O" it means that the OverlapNumber should over this setting value(>)
                in "--E N" it means that the OverlapNumber should less than this setting value(<=)
  --C		combine the overlapped regions without redundance and list all the regions
  --F <[R|D>	filterout the regions with overlap, R: combine two blocks filterout the overlapped regions and renew the table;
                D: delete the overlapped blocks from the first table, which these blocks overlap with the second talbe.
  --E <[O|N]>	enumerate the overlapped blocks(O): overlap rate between two blocks bigger than the rate set by "--OL"
                or none(N) Redundance regions: overlap rate between two blocks smaller than the rate set by "--OL"
  --X <[O|N]>	extract the overlapped segment(O);
                extract the none redundance segment(N)(filterout redundance).
  --M <str> || <1,str> || <2,str> || <1,str:2,str>	only list the region id matching situation if none or all list all:[all]
  --interpolation <str>   set the interpolation for splitting data columns,
                such as [s+,s,t+,t] and some special symbol, default: t (i.e. @col=split/\t/)
  --verbose	output verbose information to screen
  --help	output help information to screen
  --readme	Chinese readme
  --version	output version information

PS:
--OL    means if there are existing overlapping between two blocks and over this
        rate of overlapping in the "first" or "second" section of the tables
        (just could be used in "--E" option); or in the "small" size or in the
        "big" between two blocks, if the blocks were coincident with this rule,
        it will carry out the function work you need, else it will ignore to
        compare these two blocks but go on; if the limited condition is set by
        "num-bpsize", it will limited the overlapping size bigger than the "num"
        bp scale; if the limited condition is set by "numbp", it won't limited
        the overlap type, but the Total OverlapSize must bigger than or equal
        the "num" bp (>=num bp); Limit-type: "big", "small", "first", "second",
        "bpsize"

=head1 Exmple

    1.if there are existing overlapping and the size of overlapping is over 50%
    more than the small section between two blocks, filter out these two blocks
    out of the table

    % perl disposeOverlap.pl  --i1 table1.txt --f1 0-2-3 --OL 0.5-small --F >Overlap_result1.txt

    2.if there are existing overlapping and over 50% more than the small section
    between two regions, combine these two regions, meanhile preserve the unique
    regions,including the overlap not exceeding 0.5 of the small section,
    in order to get rid of the redundance

    % perl disposeOverlap.pl  --i1 table1.txt --f1 0-2-3 --i2 table2.txt --f2 0-2-3 --OL 0.5-small --C >Overlap_result2.txt

    3.list all the none overlapping or total length of overlapped segments less
    than the first table regions

    % perl disposeOverlap.pl  --i1 table1.txt --f1 0-1-2-3 --i2 table2.txt --f2 0-1-2-3 --OL 0.5-first --mN 2 --E N >Overlap_result3.txt

    4.list the two table with considerable overlapping(it can be controlled by
    the "--mR & mN"), and just list the accurately matching ID of "Variation"
    (set by "--M" option) in first table

    % perl disposeOverlap.pl --i1 table1.txt --f1 0-1-2-3 --i2 table2.txt --f2 0-1-2-3  --OL 0.1-small --mN 1 --E O --M 1,"^Variation$" >Overlap_result4.txt

=cut

use strict;
use Getopt::Long;
use Data::Dumper;

my ($input1,$inform1,$input2,$inform2,$OverlapLimited,$Final,$minNum,$Combine,$Filterout,$Enumerate,$Extract,$matchingID,$Interpolation,$Verbose,$Help,$Readme,$Version);
my %opts;
GetOptions(
	\%opts,
	"i1:s"=>\$input1,
	"f1:s"=>\$inform1,
	"i2:s"=>\$input2,
	"f2:s"=>\$inform2,
	"OL:s"=>\$OverlapLimited,
	"final:s"=>\$Final,
	"mN:i"=>\$minNum,
	"C"=>\$Combine,
	"F:s"=>\$Filterout,
	"E:s"=>\$Enumerate,
	"X:s"=>\$Extract,
	"M:s"=>\$matchingID,
	"interpolation:s"=>\$Interpolation,
	"verbose"=>\$Verbose,
	"help"=>\$Help,
	"readme"=>\$Readme,
	"version"=>\$Version
);
if (defined $Readme)
{
    readme(); exit;
}
die "  Author: BENM, binxiaofeng\@gmail.com\n  Version: 3.3,  Date: 2009-01-28\n" if (defined $Version);
die `pod2text $0` if (($Help)||((!defined $Enumerate)&&(!defined $Filterout)&&(!$Combine)&&(!$Extract)));



die("
Combine Overlap\n
Usage:   disposeOverlap.pl --C\n
Options:
        --i1 <str>	input the first table file [in.table1]
        --f1 <int-int-int>  || <int-int-int-int>	input the first table format [id-start-end] or [id1-id2-start-end]
        --i2 <str> input the first table file [in.table2]
        --f2 <int-int-int>  || <int-int-int-int>	input the first table format [id-start-end] or [id1-id2-start-end]
        --OL <num-str>	set the overlapped limited condition [OverlapRate-LimitedType], LimitedType default:0-small
        --M <str> || <1,str> || <2,str> || <1,str:2,str>	only list the region id matching situation if none or all list all:[Matching ID]
        --C		combine the overlapped regions without redundance and list all the regions [null]\n
Example:1. perl disposeOverlap.pl --C --i1 table1.txt --f1 0-2-3 --OL 0 > Combine_Overlap_result1.txt
        2. perl disposeOverlap.pl --C --i1 table1.txt --f1 0-2-3 --i2 table2.txt --f2 0-2-3 --OL 0.1-big > Combine_Overlap_result2.txt\n
") if ( ($Combine) && ( (!defined $input1) || (!defined $inform1) ) );

die("
Filterout Overlap\n
Usage:   disposeOverlap.pl --F\n
Options:
        --i1 <str>	input the first table file [in.table1]
        --f1 <int-int-int>  || <int-int-int-int>	input the first table format [id-start-end] or [id1-id2-start-end]
        --i2 <str> input the first table file [in.table2]
        --f2 <int-int-int>  || <int-int-int-int>	input the first table format [id-start-end] or [id1-id2-start-end]
        --OL <num-str>	set the overlapped limited condition [OverlapRate-LimitedType], LimitedType default:0-small
        --M <str> || <1,str> || <2,str> || <1,str:2,str>	only list the region id matching situation if none or all list all:[Matching ID]
        --F <R|D>	filterout the regions with overlap [null]\n
Example:1. perl disposeOverlap.pl  --F R --i1 table1.txt --f1 0-2-3 --OL 0.5-small > Filter_Overlap_result1.txt
        2. perl disposeOverlap.pl  --F D --i1 table1.txt --f1 0-2-3 --i2 table2.txt --f2 0-2-3 --OL 100-bpsize > Filter_Overlap_result2.txt\n
") if ( ($Filterout) && ( ($Filterout ne "R") || ($Filterout ne "D") ) && ( (!defined $input1) || (!defined $inform1) ) );

die("
Enumerate Overlap\n
Usage:   disposeOverlap.pl --E <O|N>\n
Options:
        --i1 <str>	input the first table file [in.table1]
        --f1 <int-int-int>  || <int-int-int-int>	input the first table format [id-start-end] or [id1-id2-start-end]
        --i2 <str> input the first table file [in.table2]
        --f2 <int-int-int>  || <int-int-int-int>	input the first table format [id-start-end] or [id1-id2-start-end]
        --OL <num-str>	set the overlapped limited condition [OverlapRate-LimitedType] LimitedType can be null, default: 0
        --final		Limit the final overlap limited conditions
        --mN <int>	set the minimuim limited overlapping number: [1] for N option it is maxmuim, default: 1
        --M <str> || <1,str> || <2,str> || <1,str:2,str>	only list the region id matching situation if none or all list all:[Matching ID]
        --E <[O|N]>	enumerate the overlapped blocks [null]\n
Example:1. perl disposeOverlap.pl --E O --i1 table1.txt --f1 0-1-2-3 --i2 table2.txt --f2 0-1-2-3  --OL 0.1-first --mN 1  --M Variation > List_Overlap_result.txt
        2. perl disposeOverlap.pl --E N --i1 table1.txt --f1 0-1-2-3 --i2 table2.txt --f2 0-1-2-3  --OL 100bp --mN 10 > None_Overlap_result.txt\n
") if ( ($Enumerate) && ( ($Enumerate ne "O") || ($Enumerate ne "N") ) && ( (!defined $input1) || (!defined $inform1) ) );

die("
eXtract Overlap\n
Usage:   disposeOverlap.pl --e <O|N>\n
Options:
        --i1 <str>	input the first table file [in.table1]
        --f1 <int-int-int>  || <int--int-int-int>	input the first table format [id-start-end] or [id1-id2-start-end]
        --i2 <str> input the first table file [in.table2]
        --f2 <int-int-int>  || <int--int-int-int>	input the first table format [id-start-end] or [id1-id2-start-end]
        --M <str> || <1,str> || <2,str> || <1,str:2,str>	only list the region id matching situation if none or all list all:[Matching ID]
        --X <[O|N]>	extract the overlapped segment(O);  extract the none redundance segment(N)(filterout redundance).\n
Example:1. perl disposeOverlap.pl --X O --i1 table1.txt --f1 0-2-3 > Overlap_result1.txt
        2. perl disposeOverlap.pl --X N --i1 table1.txt --f1 0-2-3 > None_Overlap_result1.txt
        3. perl disposeOverlap.pl --X O --i1 table1.txt --f1 0-1-2-3 --i2 table2.txt --f2 0-1-2-3 --M Variation > Overlap_result2.txt
        4. perl disposeOverlap.pl --X N --i1 table1.txt --f1 0-2-3 --i2 table2.txt --f2 0-2-3 > None_Overlap_result2.txt\n
") if ( ($Extract) && ( ($Extract ne "O") || ($Extract ne "N") ) && ( (!defined $input1) || (!defined $inform1) ) );

$OverlapLimited = (defined $OverlapLimited) ? $OverlapLimited : 0;
$minNum = (defined $minNum) ? $minNum : 1;
my @orate=();
my ($minRate,$limitType,$minSize);
if (defined $OverlapLimited)
{
    @orate=split /-/,$OverlapLimited;
    $minRate = ($orate[0] =~ m/\d+/) ? $orate[0] : "";
    if ($orate[0] =~ m/bp/)
    {
        $orate[0] =~ s/bp//;
        $minSize = $orate[0];
        $minRate = 0;
    }
    die "minRate:$minRate is not a available value!" if (($minRate !~ m/^\d+$/)&&($minRate !~ m/^\d+\.\d+$/)&&(($minRate !~ m/^\d+bp$/)));
    $limitType = ((defined $orate[1])&&($orate[1] =~ m/\w+/)) ? $orate[1] : "";
}
my $bpsize = $minRate if ( (defined $limitType) && ($limitType =~ m/bpsize/i) );
$minNum ||= 0;
$matchingID ||= "all";
$Interpolation ||="t";

chomp $matchingID;
my $matchingT="";
my ($T1,$matchingT1,$T2,$matchingT2)=("","","","");
if ($matchingID ne "all")
{
    $matchingID=~s/\s+//g;
    if ($matchingID=~m/\:/g)
    {
        ($matchingT1,$matchingT2)=split/\:/,$matchingID;
        ($T1,$matchingT1)=split/\,/,$matchingT1;
        ($T2,$matchingT2)=split/\,/,$matchingT2;
    }
    elsif (($matchingID=~m/\,/)&&($matchingID !~ m/\:/g))
    {
        ($matchingT,$matchingID)=split/\,/,$matchingID;
        if ($matchingT==1)
        {
            $T1=1;
            $matchingT1=$matchingID;
        }
        if ($matchingT==2)
        {
            $T2=2;
            $matchingT2=$matchingID;
        }
    }
    elsif (($matchingID !~m/\,/)&&($matchingID !~ m/\:/g))
    {
        ($T1,$matchingT1,$T2,$matchingT2)=(1,$matchingID,2,$matchingID);
    }
}

my ($id1,$rd1,$s1,$e1)=("","","","");
my ($id2,$rd2,$s2,$e2)=("","","","");
if (defined $inform1)
{
    if (table_col($inform1) == 4)
    {
        ($id1,$rd1,$s1,$e1)=table_col($inform1);
    }
    else
    {
        ($id1,$s1,$e1)=table_col($inform1);
    }
}

if (defined $inform2)
{
    if (table_col($inform2) == 4)
    {
        ($id2,$rd2,$s2,$e2)=table_col($inform2);
    }
    else
    {
        ($id2,$s2,$e2)=table_col($inform2);
    }
}

my %FirstTable=read_table($input1,$id1,$s1,$e1,$rd1,$T1,$matchingT1,1) if (defined $input1);
my %SecondTable=read_table($input2,$id2,$s2,$e2,$rd2,$T2,$matchingT2,2) if (defined $input2);

if ( (defined $input1) && (!defined $input2) )
{

    combine_overlap(\%FirstTable) if (defined $Combine);

    filterout_overlap(\%FirstTable) if ((defined $Filterout)&&($Filterout eq "R"));

    enumerate_overlap(\%FirstTable,\%FirstTable,$Enumerate) if (defined $Enumerate);

    extract_overlap(\%FirstTable) if (defined $Extract);

}

if (defined $input2)
{
    enumerate_overlap(\%FirstTable,\%SecondTable,$Enumerate) if (defined $Enumerate);
    filterout_overlap(\%FirstTable,\%SecondTable) if ((defined $Filterout)&&($Filterout eq "D"));

    if ((defined $Combine) ||  (defined $Filterout) )
    {
        my %CombineTable;
        foreach  my $id1 (sort keys %FirstTable)
        {
            my $table1=$FirstTable{$id1};
            push @{$CombineTable{$id1}},@$table1;
            delete $FirstTable{$id1};
        }
        delete @FirstTable {keys %FirstTable};
        foreach  my $id2 (sort keys %SecondTable)
        {
            my $table2=$SecondTable{$id2};
            push @{$CombineTable{$id2}},@$table2;
            delete $SecondTable{$id2};
        }
        delete @SecondTable {keys %SecondTable};

        combine_overlap(\%CombineTable) if (defined $Combine);
        filterout_overlap(\%CombineTable) if ((defined $Filterout)&&($Filterout eq "R"));
        extract_overlap(\%CombineTable) if (defined $Extract);
    }

}

print STDERR "overlap disposing work has completed!\n";

####################################################
################### Sub Routines ###################
####################################################

sub table_col
{
    my $string=shift;
    chomp $string;
    my @table;
    if ($string =~ /\-/)
    {
        @table=split /\-/,$string;
    }
    elsif ($string =~ /\,/)
    {
        @table=split /\,/,$string;
    }
    return @table;
}

sub read_table
{
    my ($file,$id,$s,$e,$rd,$t,$matching_id,$input_num)=@_;
    my %Table=();
    open (IN,$file) || die "can't open $file for reading:$!";
    while (<IN>)
    {
        chomp;
        my @col;
        if ($Interpolation eq "s+")
        {
            @col=split /\s+/,$_;
        }
        elsif ($Interpolation eq "s")
        {
            @col=split /\s/,$_;
        }
        elsif ($Interpolation eq "t+")
        {
            @col=split /\t+/,$_;
        }
        elsif ($Interpolation eq "t")
        {
            @col=split /\t/,$_;
        }
        else
        {
            @col=split/$Interpolation/,$_;
        }

        my $ID=$col[$id];
        chomp $ID;
        $ID =~ s/[;,:]$//;
        next if ((defined $Enumerate)&&($input_num==2)&&(!exists $FirstTable{$ID}));
        if ( ($col[$s] =~ /\d+/) && ($col[$e] =~ /\d+/) )
        {
            my $Start=$col[$s];
            my $End=$col[$e];
            if ((defined $rd)&&($rd ne ""))
            {
                my $RegionID=$col[$rd];
                chomp $RegionID;
                $RegionID =~ s/[;,:]$//;
                push @{$Table{$ID}},[$Start,$End,$RegionID] if ((!defined $t)||($t eq "")||($RegionID =~ m/$matching_id/i)||($matchingID eq "all"));
            }
            else
            {
                push @{$Table{$ID}},[$Start,$End];
            }
        }
        #else
        #{
        #    if ($rd ne "")
        #    {
        #        print STDERR "Warning file$input_num error:$col[$id]\t$col[$s]\t$col[$e]\t$col[$rd]\n" unless ( ($Enumerate) || ($Filterout) );
        #    }
        #    else
        #    {
        #        print STDERR "Warning file$input_num error:$col[$id]\t$col[$s]\t$col[$e]\n" unless ( ($Enumerate) || ($Filterout) );
        #    }
        #}
    }
    close IN;

    return %Table;
}

sub combine_overlap
{
    my ($hash_p,$print_mark)=@_;
    $limitType ||= "small";
    if ((!defined $print_mark)||($print_mark eq ""))
    {
        if ($rd1 ne "")
        {
            print "ID\tStart\tEnd\tCombinedNum\tCombinedTableID...\n";
        }
        else
        {
            print "ID\tStart\tEnd\n";
        }
    }
    foreach  my $table_id (keys %$hash_p)
    {
        my @array=();
        my @array_order = (exists $hash_p->{$table_id})  ? (sort {$a->[0]<=>$b->[0]} @{$hash_p->{$table_id}}) : ();
        print STDERR "combine overlap on $table_id\n" if($Verbose);
        if ((defined $array_order[0][2])&&($array_order[0][2] ne ""))
        {
            push @array,[0,0,""];
        }
        else
        {
            push @array,[0,0];
        }
        my $n = scalar @array_order;
        my @compare=();
        for (my $j=0;$j<$n;$j++)
        {
            my ($S1,$E1,$regionID1,$S2,$E2,$regionID2)=("","","","","","");

            $S1=$array_order[$j][0];
            $E1=$array_order[$j][1];
            $regionID1=$array_order[$j][2] if ($rd1 ne "");

            if ($j<$n-1)
            {
                $S2=$array_order[$j+1][0];
                $E2=$array_order[$j+1][1];
                $regionID2=$array_order[$j+1][2] if ($rd2 ne "");

                if ( ($S1<=$array[-1][1]+1) )
                {
                    if ($E1>=$array[-1][1]+1)
                    {
                        if ( $OverlapLimited ne "" )
                        {
                            @compare=compare_overlap ([$array[-1][0],$array[-1][1]],[$S1,$E1]);
                            if (scalar (@compare) ==2)
                            {
                                if ((defined $array_order[$j][2])&&(defined $array[-1][2])&&($array_order[$j][2] ne ""))
                                {
                                    $array[-1][1]=$E1;
                                    $array[-1][2].="\t".$regionID1 unless ($array[-1][2] =~ m/$regionID1/g);
                                }
                                else
                                {
                                    $array[-1][1]=$E1;
                                }
                            }
                            else
                            {
                                if ((defined $array_order[$j][2])&&($array_order[$j][2] ne ""))
                                {
                                    push @array,[$S1,$E1,$regionID1];
                                }
                                else
                                {
                                    push @array,[$S1,$E1];
                                }
                            }
                        }
                        else
                        {
                            if ((defined $array_order[$j][2])&&($array_order[$j][2] ne ""))
                            {
                                $array[-1][1]=$E1;
                                $array[-1][2].="\t".$regionID1 unless ($array[-1][2] =~ m/$regionID1/g);
                            }
                            else
                            {
                                $array[-1][1]=$E1;
                            }
                        }
                    }
                    else
                    {
                        if (($rd1 ne "")&&($rd2 ne ""))
                        {
                            $array[-1][2].="\t".$regionID1 unless ((defined $array[-1][2])&&($array[-1][2] =~ m/$regionID1/));
                        }
                    }
                    next;
                }
                elsif ( ($E1<$S2-1) && ($S1>$array[-1][1]+1) )
                {
                    if ($rd1 ne "")
                    {
                        push @array,[$S1,$E1,$regionID1];
                    }
                    else
                    {
                        push @array,[$S1,$E1];
                    }
                    next;
                }
                elsif ( ($E1>=$E2-1) && ($S1>$array[-1][1])+1 )
                {
                    if ($OverlapLimited ne "")
                    {
                        @compare=compare_overlap ([$S1,$E1],[$S2,$E2]);
                        if (scalar (@compare) ==2)
                        {
                            if ($rd1 ne "")
                            {
                                push @array,[$S1,$E1,$regionID1];
                            }
                            else
                            {
                                push @array,[$S1,$E1];
                            }
                        }
                        else
                        {
                            if ( ($rd1 ne "") && ($rd2 ne "") )
                            {
                                push @array,[$S1,$E1,$regionID1];
                                push @array,[$S2,$E2,$regionID2];
                            }
                            else
                            {
                                push @array,[$S1,$E1];
                                push @array,[$S2,$E2];
                            }
                        }
                    }
                    else
                    {
                        if ($rd1 ne "")
                        {
                            push @array,[$S1,$E1,$regionID1];
                        }
                        else
                        {
                            push @array,[$S1,$E1];
                        }
                    }
                    next;
                }
                elsif ( ($E1>=$S2-1) && ($E1<=$E2-1) && ($S1>$array[-1][1]+1) )
                {
                    if ($OverlapLimited ne "")
                    {
                        @compare=compare_overlap ([$S1,$E1],[$S2,$E2]);
                        if (scalar (@compare) ==2)
                        {
                            if ( ($rd1 ne "") && ($rd2 ne "") )
                            {
                                $regionID1.="\t".$regionID2 unless ($regionID1 =~ m/$regionID2/g);
                                push @array,[$S1,$E2,$regionID1];
                            }
                            else
                            {
                                push @array,[$S1,$E2];
                            }
                        }
                        else
                        {
                            if ( ($rd1 ne "") && ($rd2 ne "") )
                            {
                                push @array,[$S1,$E1,$regionID1];
                                push @array,[$S2,$E2,$regionID2];
                            }
                            else
                            {
                                push @array,[$S1,$E1];
                                push @array,[$S2,$E2];
                            }
                        }
                    }
                    else
                    {
                        if ( ($rd1 ne "") && ($rd2 ne "") )
                        {
                            $regionID1.="\t".$regionID2 unless ($regionID1 =~ m/$regionID2/g);
                            push @array,[$S1,$E2,$regionID1];
                        }
                        else
                        {
                            push @array,[$S1,$E2];
                        }
                    }
                    next;
                }
            }
            else
            {
                if ( ($S1<=$array[-1][1]+1) )
                {
                    if ($E1>=$array[-1][1]+1)
                    {
                        if ( $OverlapLimited ne "" )
                        {
                            @compare=compare_overlap ([$array[-1][0],$array[-1][1]],[$S1,$E1]);
                            if (scalar (@compare) ==2)
                            {
                                $array[-1][1]=$E1;
                                if ($rd1 ne "")
                                {
                                    $array[-1][2].="\t".$regionID1 unless ($array[-1][2] =~ m/$regionID1/g);
                                }
                            }
                            else
                            {
                                if ($array_order[$j][2] ne "")
                                {
                                    push @array,[$S1,$E1,$regionID1];
                                }
                                else
                                {
                                    push @array,[$S1,$E1];
                                }
                            }
                        }
                        else
                        {
                            $array[-1][1]=$E1;
                            if ($rd1 ne "")
                            {
                                $array[-1][2].="\t".$regionID1 unless ($array[-1][2] =~ m/$regionID1/g);
                            }
                        }
                    }
                    else
                    {
                        next;
                    }
                }
                else
                {
                    if ($array_order[$j][2] ne "")
                    {
                        push @array,[$S1,$E1,$regionID1];
                    }
                    else
                    {
                        push @array,[$S1,$E1];
                    }
                }
            }
        }
        shift @array if ( ($array[0][1]==0) && ($array[0][0] ==0) );
        if ( (defined $print_mark) && (($print_mark eq "null")||($print_mark ne "O")) )
        {
            return @array;
        }
        else
        {
            foreach my $table (@array)
            {
                if ( ($rd1 eq "") || ($rd2 eq "") )
                {
                    print "$table_id\t$table->[0]\t$table->[1]\n";
                }
                elsif ( (defined $table->[2]) && ($table->[2] ne "" ) && ($n != 0) )
                {
                    my @CombineNumber=split/\s+/,$table->[2];
                    my $n=scalar (@CombineNumber);
                    print "$table_id\t$table->[0]\t$table->[1]\t";
                    print "$n\t$table->[2]\t" unless (defined $Extract);
                    print "\n";
                }
            }
        }
    }
}

sub filterout_overlap
{
    my ($table1_hash,$table2_hash)=@_;
    $limitType ||= "small";
    if (!defined $Extract)
    {
        if ($rd1 ne "")
        {
            print "ID\tFirstTableID\tStart\tEnd\n";
        }
        else
        {
            print "ID\tStart\tEnd\n";
        }
    }
    if ((!defined $table2_hash)||(keys %$table2_hash==0))
    {
        foreach  my $table_id (sort keys %$table1_hash)
        {
            my @table_order = (exists $table1_hash->{$table_id})  ? (sort {$a->[0]<=>$b->[0]} @{$table1_hash->{$table_id}}) : ();
            print STDERR "filterout overlap on $table_id\n" if ($Verbose);
            my ($tempS,$tempE,$preS,$preE,$nextS,$nextE) = (0,0,0,0,0,0);
            my $n = scalar @table_order;
            my @compare1;
            my @compare2;
            for (my $k=0;$k<$n;$k++)
            {
                $tempS=$table_order[$k][0];
                $tempE=$table_order[$k][1];
                if ($k>0)
                {
                    if ($compare1[0] ne "")
                    {
                        $preS=($compare1[0]<$table_order[$k-1][0]) ? $compare1[0] : $table_order[$k-1][0];
                    }
                    else
                    {
                        $preS=$table_order[$k-1][0];
                    }
                    $preE=($compare1[1]>$table_order[$k-1][1]) ? $compare1[1] : $table_order[$k-1][1];
                }
                elsif ($k==0)
                {
                    $preS=0;
                    $preE=0;
                }

                if ($k<$n-1)
                {
                    $nextS = $table_order[$k+1][0];
                    $nextE = $table_order[$k+1][1];
                    if ($OverlapLimited ne "")
                    {
                        @compare1=compare_overlap ([$preS,$preE],[$tempS,$tempE]);
                        @compare2=compare_overlap ([$nextS,$nextE],[$tempS,$tempE]);
                        if ((@compare1==4) && (@compare2==4) )
                        {
                            if ( (defined $table_order[$k][2])&&($table_order[$k][2] ne "") )
                            {
                                my $regionID=$table_order[$k][2];
                                print "$table_id\t$regionID\t$tempS\t$tempE\n";
                            }
                            else
                            {
                                print "$table_id\t$tempS\t$tempE\n";
                            }
                        }
                    }
                    else
                    {
                        if ( ($tempS>$preE+1) && ($tempE<$nextS-1) )
                        {
                                if ( (defined $table_order[$k][2])&&($table_order[$k][2] ne "") )
                                {
                                    my $regionID=$table_order[$k][2];
                                    print "$table_id\t$regionID\t$tempS\t$tempE\n";
                                }
                                else
                                {
                                    print "$table_id\t$tempS\t$tempE\n";
                                }
                        }
                        else
                        {
                            next;
                        }
                    }
                }
                elsif ($k==$n-1)
                {
                    if ($OverlapLimited ne "")
                    {
                        my @compare=compare_overlap ([$preS,$preE],[$tempS,$tempE]);
                        if (@compare==4)
                        {
                            if ( (defined $table_order[$k][2])&&($table_order[$k][2] ne "") )
                            {
                                my $regionID=$table_order[$k][2];
                                print "$table_id\t$regionID\t$tempS\t$tempE\n";
                            }
                            else
                            {
                                print "$table_id\t$tempS\t$tempE\n";
                            }
                        }
                    }
                    else
                    {
                        if ($tempS>$preE+1)
                        {
                            if ( (defined $table_order[$k][2])&&($table_order[$k][2] ne "") )
                            {
                                my $regionID=$table_order[$k][2];
                                print "$table_id\t$regionID\t$tempS\t$tempE\n";
                            }
                            else
                            {
                                print "$table_id\t$tempS\t$tempE\n";
                            }
                        }
                        else
                        {
                            next;
                        }
                    }
                }
            }
        }
    }
    else
    {
        foreach  my $table_id (sort keys %$table1_hash)
        {
            print STDERR "filterout overlap on $table_id\n" if ($Verbose);
            my @table1_order = (exists $table1_hash->{$table_id})  ? (sort {$a->[0]<=>$b->[0]} @{$table1_hash->{$table_id}}) : ();
            my @table2_order = (exists $table2_hash->{$table_id})  ? (sort {$a->[0]<=>$b->[0]} @{$table2_hash->{$table_id}}) : ();
            if (@table2_order<1)
            {
                for (my $i=0;$i<@table1_order;$i++)
                {
                    my $S=$table1_order[$i][0];
                    my $E=$table1_order[$i][1];
                    if ($table1_order[$i][2] ne "")
                    {
                        my $regionID=$table1_order[$i][2];
                        print "$table_id\t";
                        print "$regionID\t" unless (defined $Extract);
                        print "$S\t$E\n";
                    }
                    else
                    {
                        print "$table_id\t$S\t$E\n";
                    }
                }
            }
            else
            {
                for (my $j=0;$j<@table1_order;$j++)
                {
                    my $S1=$table1_order[$j][0];
                    my $E1=$table1_order[$j][1];
                    my $regionID=$table1_order[$j][2] if ( (defined $table1_order[$j][2])&&($table1_order[$j][2] ne "") );
                    if ($S1>=$table2_order[-1][1])
                    {
                        $S1 = $S1+1 if ($S1==$table2_order[-1][1]);
                        if ($table1_order[$j][2] ne "")
                        {
                            print "$table_id\t";
                            print "$regionID\t" unless (defined $Extract);
                            print "$S1\t$E1\n";
                        }
                        else
                        {
                            print "$table_id\t$S1\t$E1\n";
                        }
                        last;
                    }
                    if (scalar @table2_order>0)
                    {
                        my $filterID_tmp="";
                        for (my $k=0;$k<@table2_order;$k++)
                        {
                            my $S2=$table2_order[$k][0];
                            my $E2=$table2_order[$k][1];
                            my $filterID=$table2_order[$k][2] if ((defined $table2_order[$k][2])&&($table2_order[$k][2] ne ""));
                            $filterID=$filterID_tmp if ($filterID_tmp ne "");
                            next if ($E2<$S1);
                            if ($S2>=$E1)
                            {
                                if ( (defined $table1_order[$j][2])&&($table1_order[$j][2] ne "") )
                                {
                                    print "$table_id\t";
                                    print "$regionID\t" unless (defined $Extract);
                                    print "$S1\t$E1";
                                    if ((defined $filterID_tmp)&&($filterID_tmp ne ""))
                                    {
                                        print "\t$filterID_tmp" unless (defined $Extract);
                                    }
                                    print "\n";
                                }
                                else
                                {
                                    print "$table_id\t$S1\t$E1\n";
                                }
                                last;
                            }
                            elsif (($S2<$S1)&&($E2>$S1)&&($E2<=$E1))
                            {
                                if ($E1-$E2>1)
                                {
                                    $S1=$E2+1;
                                    $filterID_tmp=$table2_order[$k][2] if ((defined $table2_order[$k][2])&&($table2_order[$k][2] ne ""));
                                    next;
                                }
                                else
                                {
                                    last;
                                }
                            }
                            elsif (($S2<=$S1)&&($E2>=$E1))
                            {
                                last;
                            }
                            elsif (($S2>=$S1)&&($S2<$E1))
                            {
                                if ($S2>$S1+1)
                                {
                                    if ((defined $table1_order[$j][2])&&($table1_order[$j][2] ne ""))
                                    {
                                        print "$table_id\t";
                                        print "$regionID\t" unless (defined $Extract);
                                        print "$S1\t".($S2-1)."\t";
                                        if ((defined $filterID)&&(defined $filterID ne ""))
                                        {
                                            print "$filterID" unless (defined $Extract);
                                        }
                                        print "\n";
                                        $filterID_tmp="";
                                    }
                                    else
                                    {
                                        print "$table_id\t$S1\t".($S2-1)."\n";
                                    }
                                }
                                if ($E2<$E1)
                                {
                                    $S1=$E2+1;
                                    $filterID_tmp=$table2_order[$k][2] if ((defined $table2_order[$k][2])&&($table2_order[$k][2] ne ""));
                                    next;
                                }
                                else
                                {
                                    last;
                                }
                            }
                        }
                        if ($S1>=$table2_order[-1][1])
                        {
                            if ( (defined $table1_order[$j][2])&&($table1_order[$j][2] ne "") )
                            {
                                print "$table_id\t";
                                print "$regionID\t" unless (defined $Extract);
                                print "$S1\t$E1\t";
                                print "$filterID_tmp" unless (defined $Extract);
                                print "\n";
                            }
                            else
                            {
                                print "$table_id\t$S1\t$E1\n";
                            }
                        }
                    }
                }

            }
        }
    }
}

sub enumerate_overlap
{
    my ($Fst_table,$Sec_table,$List_form)=@_;

    chomp $List_form;
    my $overlap_num=0;
    if  (($List_form eq "O") || ($List_form eq "N") )
    {
        if ( ($rd1 ne "") || ($rd2 ne "") )
        {
            print "ID\t";
            print "FirstTableID\t" if ($rd1 ne "");
            print "Start\tEnd\tLength\tOverlapNumber\tOverlapSize\tOverlapRate\t";
            print "SecondTableID:" if ($rd2 ne "");
            print "Start,End,Length,OverlapSize...\n" ;
        }
        else
        {
            print "ID\tStart\tEnd\tLength\tOverlapNumber\tOverlapSize\tOverlapRate\tStart,End,Length,OverlapSize...\n" if ($List_form eq "N");
            print "ID\tStart\tEnd\tLength\tOverlapNumber\tOverlapSize\tOverlapRate\tStart,End,Length,OverlapSize...\n" if ($List_form eq "O");
        }
    }
    foreach  my $table_id (sort keys %$Fst_table)
    {
        my @fst_tab = (exists $Fst_table->{$table_id}) ? (sort {$a->[0] <=> $b->[0]} @{$Fst_table->{$table_id}}) : ();
        my @sec_tab = (exists $Sec_table->{$table_id}) ? (sort {$a->[0] <=> $b->[0]} @{$Sec_table->{$table_id}}) : ();

        print STDERR "find overlap on $table_id\n" if($Verbose);

        my $sec_begin=0;

        for (my $i=0; $i<@fst_tab; $i++)
        {
            my $fst_size = $fst_tab[$i][1] - $fst_tab[$i][0] + 1;
            my @overlap=();
            my $total_overlap_size=0;
            for (my $j=$sec_begin; $j<@sec_tab; $j++)
            {
                next if ((!defined $input2) && (!defined $inform2) &&
                    (($rd1 ne "") && ($sec_tab[$j][2] eq $fst_tab[$i][2]) && ($fst_tab[$j][0]==$sec_tab[$j][0]) && ($fst_tab[$j][1]==$sec_tab[$j][1]) ) );
                if ($sec_tab[$j][1] < $fst_tab[$i][0])
                {
                    next;
                }
                if ($sec_tab[$j][0] > $fst_tab[$i][1])
                {
                    last;
                }
                $sec_begin=$j if (scalar @overlap==0);

                if ($limitType ne "")
                {
                    my @compare=compare_overlap($fst_tab[$i],$sec_tab[$j]);
                    next if ( ($List_form eq "O") && (@compare==4) );
                    last if ( ($List_form eq "N") && (@compare==2) );
                }

                my $sec_size = $sec_tab[$j][1] - $sec_tab[$j][0] + 1;
                my $overlap_size = overlap_size($fst_tab[$i],$sec_tab[$j]);
                $total_overlap_size += $overlap_size;

                if (($rd2 ne "")&&($sec_tab[$j][2] ne ""))
                {
                    push @overlap,["$sec_tab[$j][2]:$sec_tab[$j][0],$sec_tab[$j][1],$sec_size",$overlap_size];
                }
                else
                {
                    push @overlap,["$sec_tab[$j][0],$sec_tab[$j][1],$sec_size",$overlap_size];
                }
            }
            @overlap=sort{$b->[1]<=>$a->[1]}@overlap;          #overlap列举由overlap size从大到小罗列
            my $overlap_out="";
            $overlap_num=scalar(@overlap);
            if ($overlap_num>0)
            {
                map{$overlap_out.="\t".(join ",",@$_)}@overlap;
            }
            my $overlap_rate=$total_overlap_size/$fst_size;
            if (($rd1 ne "")&&($fst_tab[$i][2] ne ""))
            {
                if (  ($List_form eq "O") && ($overlap_num>=$minNum) )
                {
                    if ((defined $Final)||($limitType eq ""))
                    {
                        next if ( (defined $minRate) && ($overlap_rate<$minRate) && (!defined $bpsize) );
                    }
                    next if ( (defined $minSize) && ($total_overlap_size<$minSize));
                }
                elsif ( ($List_form eq "N") && ($overlap_num<=$minNum) )
                {
                    if ((defined $Final)||($limitType eq ""))
                    {
                        next unless ( ((!defined $bpsize)&&($total_overlap_size<=$fst_size*$minRate)) || ((!defined $minSize)&&(defined $bpsize)&&($total_overlap_size<=$bpsize)) );
                    }
                    next if ((defined $minSize) && ($total_overlap_size>$minSize));
                }
                else
                {
                    next;
                }
                print ($table_id."\t".$fst_tab[$i][2]."\t".$fst_tab[$i][0]."\t".$fst_tab[$i][1]."\t".$fst_size."\t".$overlap_num."\t".$total_overlap_size."\t".$overlap_rate."$overlap_out\n");
            }
            else
            {
                if (  ($List_form eq "O")  && ($overlap_num>=$minNum) )
                {
                    if ((defined $Final)||($limitType eq ""))
                    {
                        next if ((defined $minRate) && ($overlap_rate<$minRate) && (!defined $bpsize) );
                    }
                    next if ((defined $minSize) && ($total_overlap_size<$minSize));
                }
                elsif ( ($List_form eq "N") && ($overlap_num<=$minNum) )
                {
                    if ((defined $Final)||($limitType eq ""))
                    {
                        next unless ( ((!defined $bpsize)&&($total_overlap_size<=$fst_size*$minRate)) || ((!defined $minSize)&&(defined $bpsize)&&($total_overlap_size<=$bpsize)) );
                    }
                    next if ((defined $minSize) && ($total_overlap_size>$minSize));
                }
                else
                {
                    next;
                }
                print ($table_id."\t".$fst_tab[$i][0]."\t".$fst_tab[$i][1]."\t".$fst_size."\t".$overlap_num."\t".$total_overlap_size."\t".$overlap_rate."$overlap_out\n");
            }
        }
    }
}

sub extract_overlap
{
    my $block_p=shift;
    foreach  my $table_id (keys %$block_p)
    {
        my @overlap=();
        my @array_order = (exists $block_p->{$table_id})  ? (sort {$a->[0]<=>$b->[0]} @{$block_p->{$table_id}}) : ();
        if (@array_order>1)
        {
            for (my $i=0;$i<@array_order-1;$i++)
            {
                my ($S1,$E1)=($array_order[$i][0],$array_order[$i][1]);
                for (my $j=$i+1;$j<@array_order;$j++)
                {
                    my ($S2,$E2)=($array_order[$j][0],$array_order[$j][1]);
                    if ($S2>$E1)
                    {
                        last;
                    }
                    else
                    {
                        my ($S,$E)=find_overlap([$S1,$E1],[$S2,$E2]);
                        push @overlap,[$S,$E];
                    }
                }
            }
        }
        else
        {
            print "$table_id\t${$block_p->{$table_id}}[0][0]\t${$block_p->{$table_id}}[0][1]\n" if ($Extract eq "N");
        }
        $limitType = "bpsize";
        $bpsize = 0;
        my %tmp_overlap=();
        push @{$tmp_overlap{$table_id}},@overlap;
        my @Combine_array = combine_overlap(\%$block_p,"null");
        my @Overlap_array = combine_overlap(\%tmp_overlap,$Extract);
        my %Combine=();
        my %Overlap=();
        push @{$Combine{$table_id}},@Combine_array;
        push @{$Overlap{$table_id}},@Overlap_array;
        filterout_overlap(\%Combine,\%Overlap) if (($Extract eq "N")&&(@{$Combine{$table_id}}>0)&&(@{$Overlap{$table_id}}>0));
    }
}

sub find_overlap
{
    my ($block1_p,$block2_p) = @_;
    my $S = ($block1_p->[0] > $block2_p->[0]) ?  $block1_p->[0] : $block2_p->[0];
    my $E = ($block1_p->[1] < $block2_p->[1]) ?  $block1_p->[1] : $block2_p->[1];
    return ($S,$E);
}

sub overlap_size
{
    my ($block1_p,$block2_p) = @_;

    my $combine_start = ($block1_p->[0] < $block2_p->[0]) ?  $block1_p->[0] : $block2_p->[0];
    my $combine_end   = ($block1_p->[1] > $block2_p->[1]) ?  $block1_p->[1] : $block2_p->[1];

    my $overlap_size = ($block1_p->[1]-$block1_p->[0]+1) + ($block2_p->[1]-$block2_p->[0]+1) - ($combine_end-$combine_start+1);

    return $overlap_size;
}

sub compare_overlap
{
    my $block1_p = shift;
    my $block2_p = shift;

    my $S1=$block1_p->[0];
    my $E1=$block1_p->[1];
    my $S2=$block2_p->[0];
    my $E2=$block2_p->[1];
    my $overlapSize=overlap_size($block1_p,$block2_p);
    my $Size1=($E1-$S1+1);
    my $Size2=($E2-$S2+1);
    my ($big,$small);
    my $S=($S1<$S2) ? $S1 : $S2;
    my $E=($E1>$E2) ? $E1 : $E2;
    if ($Size1>$Size2)
    {
        $big=$Size1;
        $small=$Size2;
    }
    else
    {
        $big=$Size2;
        $small=$Size1;
    }
    if ($limitType eq "small")
    {
        if ($overlapSize<=$small*$minRate)
        {
            return ($S1,$E1,$S2,$E2);
        }
        else
        {
            return ($S,$E);
        }
    }
    elsif ($limitType eq "big")
    {

        if ($overlapSize<=$big*$minRate)
        {
            return ($S1,$E1,$S2,$E2);
        }
        else
        {
            return ($S,$E);
        }
    }
    elsif ($limitType eq "first")
    {
        if ($overlapSize<=$Size1*$minRate)
        {
            return ($S1,$E1,$S2,$E2);
        }
        else
        {
            return ($S,$E);
        }
    }
    elsif($limitType eq "second")
    {
        if ($overlapSize<=$Size2*$minRate)
        {
            return ($S1,$E1,$S2,$E2);
        }
        else
        {
            return ($S,$E);
        }
    }
    elsif($limitType eq "bpsize")
    {
        if ($overlapSize<=$bpsize)
        {
            return ($S1,$E1,$S2,$E2);
        }
        else
        {
            return ($S,$E);
        }
    }
    else
    {
        last;
    }
}

sub readme
{
    my $usage = <<USAGE;
(一)如何定义overlap
我们取任意两个区域:block1(S1,E1),block2(S2,E2);

1、排序(按start前后由小到大排序),找overlap,算overlap长度:

(1)互相交叉:
S1********E1
     S2************E2

S2************E2
         S1********E1
(2)互被包含:
S2************E2
  S1*******E1

S1************E1
  S2*******E2

伪代码判定: (E2>=S1) && (S2<=E1)
取Smin = (S1<S2) ? S1 : S2;
Emax = (E1>E2) ? E1 : E2;
去冗余长度 Lc=Emax-Smin+1;
overlap长度 L=L1+L2-Lc=(E1-S1+1)+(E2-S2+1)-(Emax-Smin+1)

2、代码:
sub overlap_size
{
    my (\$block1_p,\$block2_p) = @_; #([S1,E1],[S2,E2])

    my \$combine_start = (\$block1_p->[0] < \$block2_p->[0]) ?  \$block1_p->[0] : \$block2_p->[0];
    my \$combine_end   = (\$block1_p->[1] > \$block2_p->[1]) ?  \$block1_p->[1] : \$block2_p->[1];

    my \$overlap_size = (\$block1_p->[1]-\$block1_p->[0]+1) + (\$block2_p->[1]-\$block2_p->[0]+1) - (\$combine_end-\$combine_start+1);

    return \$overlap_size;
}

(二）overlap主要关系，介绍disposeOverlap.pl的主要功能
一般认为具备三种功能就可以处理诸多的overlap关系：列举(Enumerate)、合并(Combine)、筛滤(Filterout)
1、列举
列举的意思，即如果我们处理两个文件，不妨设为a文件和b文件（简称a,b)，这两个文件都有一定的区域如(start,end)作为比较；
我们要找b里的区域有多少与a中的区域有overlap，并以a作为参考，即如a中某个区域跟b中多少的区域有overlap，并列出。
不妨设a，b的格式为
Chromosome	RegionID	Start	End
其中RegionID可为这个区域性所标志的一个ID，也可心在做多个文件时overlap比较时设定为的ID。
这里多个文件的意思是,如果我的参考文件只有a,但我想跟b,c,d,e等文件做overlap比较，我可以把b,c,d,e合并为一个文件B，然后分别用RegionID标志来自不同文件所拥有的区域，以便区分；我就没必要用a文件一个个跟b,c,d,e作比较了，除非我需要得到这样单个比较的信息。
所以最终还是两个文件之间的比较。
如a中有
chr1	a-1	10	100
和b中
chr1	b-1	1	20
chr1	b-2	20	40
chr1	b-3	80	120
chr1	b-4	1	1000
皆有overlap
那么我们就要得到这样的信息
ID      FirstTableID    Start   End     Length  OverlapNumber   OverlapSize     OverlapRate     SecondTableID:Start,End,Length,OverlapSize...
chr1    a-1     10      100     91      4       144     1.58241758241758        b-1:1,20,20,11  b-4:1,1000,1000,91      b-2:20,40,21,21	b-3:80,120,41,21
我们算得a-1区域的长度为Length:91;
b-1(长度20与a-1overlap长度11),b-2(21,21),b-3(41,21),b-4（1000,91) #括号内第一个数值是b区域的长度，第二个是与a-1overlap的长度;
并算得所有与a-1overlap的长度之和为OverlapSize:144=11+21+21+91;
OverlapRate:OverlapSize/Length=1.58241758241758
然后我们可以作一些限定条件，在disposeOverlap.pl有五种限定条件，用"--OL"设置，设置方法为“数值-限定条件“或”数值“
限定条件分别为"big", "small", "first", "second", "bpsize"
"big"的意思是,取最大值为参考值如:a-1与b-1比较时，a-1长度值比b-1大，所以参考值为a-1的长度，即91;但当a-1与b-4比较时，则取b-4长度作为参考值,即1000;
"small"是相对big说的，即取两个中小的那个，上例则分别取b-1和a-1；
"first"是限定取第一个文件里的区域，在这里就在a-1与b文件比较时，都取a-1作参考，如果把比完a-1后，到比a-2与b文件的区域作比较时，就取a-2作参考；
"second"是相对first说的，即a-1与b文件比较时，分别是取了b-1,b-2,b-3,b-4作参考；
“--OL“设定的如果前面数值为0，则可知四个限定条件是一样的,限定意思是:
在有参考限定条件时，我们重新定义了overlap，如"--OL 0.6-small"，当如当a-1如b-1比较时，这里取small为参考即b-1的大小为参考，
0.6的意思是两个区域的overlap大小要大于small size(参考的b-1大小）的50%，在这里b-1/a-1显然小于60%，所以b-1就不做考虑了；
但当a-1与b-4比较时，由于small为a-1，而且，a-1完全被包含进b-4里，所以a-1/a-1为100%>60%，所以b-4符合限定条件；
这样如果我们设了"--OL 0.5-small"将会得到这样的结果：
ID      FirstTableID    Start   End     Length  OverlapNumber   OverlapSize     OverlapRate     SecondTableID:Start,End,Length,OverlapSize...
chr1    a-1     10      100     91      2       112     1.23076923076923        b-4:1,1000,1000,91      b-2:20,40,21,21
但，最后我们还作一个判断，当设了“--OL”的值大于0时，最后得到与a-1总的OverlapSize/Length(a-1长度），即OverlapRate也必须大于等于60%，在这里为123%符合。
在脚本中可以容许不设定限定条件，最设值，这样程序将不再作overlap的重新判定，只要是overlap都不过滤，只取最后OverlapRate>=60%(注意最后的判定是大于等于）那么得到的结果即如第一次显示的结果：
ID      FirstTableID    Start   End     Length  OverlapNumber   OverlapSize     OverlapRate     SecondTableID:Start,End,Length,OverlapSize...
chr1    a-1     10      100     91      4       144     1.58241758241758        b-1:1,20,20,11  b-4:1,1000,1000,91      b-2:20,40,21,21	b-3:80,120,41,21
“bpsize”是指限定了每次作overlap判定时最小overlap的长度，如我们设“--OL 40-bpsize",我们得到：
ID      FirstTableID    Start   End     Length  OverlapNumber   OverlapSize     OverlapRate     SecondTableID:Start,End,Length,OverlapSize...
chr1    a-1     10      100     91      1       91      1       b-4:1,1000,1000,91
这样在判定overlap时，b-1,b-2,b-3就被过滤，不再显示与a-1有overlap了。
如果，我们不想做overlap的限定，但我们最终需要总的OverlapSize大于一定值，只要设“numbp"就可以了，num是限定值大小，即最后的OverlapSize>=num bp。
如：--OL 144bp,结果：
ID      FirstTableID    Start   End     Length  OverlapNumber   OverlapSize     OverlapRate     SecondTableID:Start,End,Length,OverlapSize...
chr1    a-1     10      100     91      4       144     1.58241758241758        b-1:1,20,20,11  b-4:1,1000,1000,91      b-2:20,40,21,21     b-3:80,120,41,21
如果设--OL 145bp,则为空数据。
ID      FirstTableID    Start   End     Length  OverlapNumber   OverlapSize     OverlapRate     SecondTableID:Start,End,Length,OverlapSize...
这里是罗列Overlap的结果，即在脚本中用了"--E O"的功能；
但是我们有时候需要的是罗列没有overlap,或称为去冗余的结果，即我不要a中文件与b中文件有overlap的信息；
如重新定义一个新例子：
a文件：
chr1	a-1	10	100
chr1	a-2	110	130
chr1	a-3	2000	2500
b文件:
chr1	b-1	1	20
chr1	b-2	20	40
chr1	b-3	80	120
chr1	b-4	1	1000
如果我们设"--OL 0"，得:
ID      FirstTableID    Start   End     Length  OverlapNumber   OverlapSize     OverlapRate     SecondTableID:Start,End,Length,OverlapSize...
chr1    a-3     2000    2500    501     0       0       0
因为只有a-3与b文件的区域没有overlap；
但如果我们限定了overlap条件，如"--OL 0.6-small"，得：
ID      FirstTableID    Start   End     Length  OverlapNumber   OverlapSize     OverlapRate     SecondTableID:Start,End,Length,OverlapSize...
chr1    a-1     10      100     91      2       32      0.351648351648352       b-1:1,20,20,11  b-3:80,120,41,21
chr1    a-2     110     130     21      1       11      0.523809523809524       b-3:80,120,41,11
chr1    a-3     2000    2500    501     0       0       0
因为b-1,b-3与a-1比较时，b-1与a-1的overlap大小为11,small为b-1：20，11/20<60%；b-3与a-1的overlap大小为21,small为b-3：41，21/41<60%，因此，b-1和b-3不在overlap限定条件内，所以列出。
但b-2和b-4的overlap rate分别为:21/21=1>60%,91/91=1>60%，所以被过滤。
a-3在b中没有区域与之overlap，所以单列。
最后总的OverlapRate都<=60%，所以得结果。

********************************************
强调：
--OL num-LimitType
num是limit的数值，不管有没有LimitType最后都会影响总的OverlapRate和OverlapSize判定，最后的判定取的是(>=)
如果有LimitType，则有overlap条件判定，即重新定义了overlap，并非传统认为只要有1bp都算为overlap，而是根据num作为数值判定；
LimitType中,"big","small","first","second"都是对overlap rate的比较，只是参考不一样；
"bpsize"与"numbp"(numbp严格不是LimitType)是overlap size的比较,不作参考系，bpsize是判定overlap就用到，numbp，只在最后OverlapSize要大于等于的数值。
********************************************

另外在--E 中有一个"--mN"的选项，
在"--E O"中"--mN"设定的数值即为最小值，即我要得到b文件最小要有这个数值以上（包括这个数值大小OverlapNum)的区域与a中某区域有overlap，最后才输出结果。所以，mN一般取大于等于1。
而在"--E N"中，因为要得到的是非冗余区域的罗列，所以，我们要尽可能小的得到overlap的数，所以这里的数值即为罗列的最大值，所以一般这个值尽量取大，以不至于丢失信息，但也不应过大，因为过大的OverlapNum，虽然OverlapSize和OverlapRate小，但也说明有很多冗余。

列举时，为减少CPU时间，会加入
是否有overlap判定:
next if (E2<S1);
last if (S2>E1);

2、合并
顾名思义，就是把有overlap的区域合并，简单如:
(1)互相交叉:
S1********E1
     S2************E2
合并后为：（S1,E2）

S2************E2
         S1********E1
合并后为：（S2,E1）
(2)互被包含:
S2************E2
  S1*******E1
合并后为：(S2,E2)

S1************E1
  S2*******E2
合并后为：(S1,E1)

但如果我们限定了overlap条件，即重新定义了overlap就不再这么简单；
意思即我们只合并了我们定义符合overlap的区域，如果不满足就单独列出。
其实在合并这个功能，我们可以把两个文件都当一个文件作处理，因为这里只要符合条件的区域都合并了，包括自身有overlap，所以"--C"也是一个去冗余的功能。
所以这里--OL中的"first","second"就不起作用了。
如文件c
chr1	c-1	1	20
chr1	c-2	20	40
chr1	c-3	30	60
chr1	c-4	50	100
如果"--OL 0"，得：
ID      Start   End     CombinedNum     CombinedTableID...
chr1    1       100     4       c-1     c-2     c-3     c-4
因为，c-1与c-2合并得(1,40),新的区域与c-3合并得(1,60)，再与c-4合并得(1,100)。
如我们设"--OL 5-bpsize"，则有
ID      Start   End     CombinedNum     CombinedTableID...
chr1    1       20      1       c-1
chr1    20      100     3       c-2     c-3     c-4
因为--C的功能是从左至右合并的，所以如果限定了LimitType可能会导致一些偏向性答案，我们以区域的start作排序，合并了一个区域后下一个区域前跟这个合并区域进行比较，因为下一个区域是最靠近这个合并。
可是假如我们重新定义了overlap，例如我们设"--OL 0.5-small",以下情况：
A*******************B
    c***********************************d
       e***************f
AB是一个刚合并的block，现在判断AB与cd是否能合并，显然不满足“--OL 0.5-big“条件，所以AB和cd不能合并，所以现在打印AB重新建立新参考cd，下一个是ef，显然ef也是不能满足与AB合并的。
但是我们重新安排一下，如果AB与ef先比较，满足OL条件，那么AB与ef合并得Af，然后Af作为新的参考与cd比较，发现也是可以满足OL条件，最后得Ad。
可是如果是用从小到大排列是可以达到以上的效果，就需要聚类算法了。为了减少程序的复杂性，在这里就简化不加入聚类算法。
有兴趣可以考虑一下。因此建议一般设LimitType为"--OL 0"或"bpsize"是没问题的。

3、筛滤
即从自身删除有overlap冗余的区域"--F R"，或去掉与另一个文件有overlap的区域"--F D"。
“--F R”是将一个文件内的区域作比较，把一些overlap过大（由OL条件决定）的区域去掉，但由于也是作start排序，所以也会导致左偏向性的，新参考为合并区大小，因为关系复杂，所以一般建议用"--OL 0"或"--OL num-bpsize"。
“--F D”是将一个文件与另一个文件作比较，如果与第二个文件的区域有overlap，就把原第一个区域的overlap片段删掉，保留非冗余的片段，如：
A*******************B（a文件）
    c***********************************d（b文件）
就会剩Ac和Bd，但是如果本来第二个文件的区域就有冗余，如：
A*******************B（a文件）
    c***********************************d（b文件）
    　　e*********f（b文件）
就会报出Ac，Bd，Ae，fB四个区域出来了，所以建议可以先把a，b文件作一次“--C”的去冗余后再做“--F D”。

4、提取overlap片段和非overlap片段
“--X [O|N]”，这是程序新增的功能，主要用于把overlap片段提出来“--X O”，如：
a*********b
    c*********d
提出的overlap片段即为cb；
或把overlap去掉后去冗余的片段提出来“--X N”，如：
a*********b
    c*********d
提出的非overlap去冗余的片段即为ac，bd。
在这里不考虑OL条件，所以只要有1bp都认为是overlap。

5、其他功能：
--M  是用于筛选RegionID用的，用正则表达式匹配的方法过滤。如：--M Variation即光处理1和2文件里的包含Variation作为RegionID的块。如果--M 1,Variation:2,mRNA，即处理1中的Variation和2中的mRNA比较，一般不用设置。
如:可设--M 1,"^Variation\$":2,mRNA
--interpolation 是用于读文件的，因为有些文件是用空格分列的，有些文件是用tab分列的，或有别的，可用--interprolation选项设置，如--interprolation s+即相当于读文件是split /\\s+/的功能，默认是s+，一般不用设置。

for JiJi
2008-12-16

********************************************
更新:3.2版本后,"--OL"将不再限制最后的limite条件,即只作overlap定义,但最后输出不会限制,如:
"--OL 0.6-small"的意思只作两个blocks的overlap定义,最后不需要总的OverlapRate>=0.6 of the block size of first table,如果需要作这一步,只需加入"--final".
增添了遍历优化.
********************************************

********************************************
3.3版版本后,在"--E O"的功能中，如果有Limit-type: "big", "small", "first", "second","bpsize"则会影响overlap的重定义，即每对blocks作overlap比较，都会按此定义作限定条件，但只有加入"--final"，才会影响最后的输出结果的限定如上。
但如果没有Limit-type，则不作overlap的重定义，在这里两个文件的每对区域进行比较只要有1bp的overlap都算是overlap，但即使不加入"--final"，如果仅是数字，如"--OL 0.1"即会筛选最后OverlapRate>=0.1的结果输出；
如果如"--OL 10bp"则最后会筛选OverlapSize>=10的结果输出，当然"--E N"最后输出条件刚好相反。
那么OL，现在有以下几种不同的设置:
"--OL 0.1":  只限定最后的OverlapRate，作overlap计算时只要有1bp都算;
"--OL 0.1-small":  限定overlap比较条件，即两个区域只有当overlap大小大于最小区域长度的10%才算为有overlap，但最后输出不限定OverlapRate;
"--OL 0.1-small -final":  比较定义overlap时同--OL 0.1-small，但输出结果限定OverlapRate>=0.1才输出，这里重申OverlapRate=OverlaSize/Length (title里的值);
"--OL 10bp":  只限定最后的OverlapSize, 作overlap计算时只要有1bp都算;
"--OL 10-bpsize": 限定overlap比较条件，即两个区域只有当overlap大小大于（不等于)10才认为有overlap，但最后输出不限定OverlapSize;
--OL 10-bpsize -final  比较定义overlap时同--OL 10-bpsize，但输出结果限定OverlapSize>=10才输出;
这里OverlapRate,OverlapSize,Length都是title的值即为总的Overlap比率，总的Overlap大小，和第一文件的区域的长度
最后输出作了小修改，以后会以第一个文件的首位置作为座标尺(排序)列表，第二个文件与之overlap，会按overlap大小从大到小在后面列举出。

大年初三凌晨2:39am, Happy 牛 Year!
********************************************

USAGE
    print $usage;
}
