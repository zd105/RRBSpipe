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
            @overlap=sort{$b->[1]<=>$a->[1]}@overlap;          #overlap�о���overlap size�Ӵ�С����
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
(һ)��ζ���overlap
����ȡ������������:block1(S1,E1),block2(S2,E2);

1������(��startǰ����С��������),��overlap,��overlap����:

(1)���ཻ��:
S1********E1
     S2************E2

S2************E2
         S1********E1
(2)��������:
S2************E2
  S1*******E1

S1************E1
  S2*******E2

α�����ж�: (E2>=S1) && (S2<=E1)
ȡSmin = (S1<S2) ? S1 : S2;
Emax = (E1>E2) ? E1 : E2;
ȥ���೤�� Lc=Emax-Smin+1;
overlap���� L=L1+L2-Lc=(E1-S1+1)+(E2-S2+1)-(Emax-Smin+1)

2������:
sub overlap_size
{
    my (\$block1_p,\$block2_p) = @_; #([S1,E1],[S2,E2])

    my \$combine_start = (\$block1_p->[0] < \$block2_p->[0]) ?  \$block1_p->[0] : \$block2_p->[0];
    my \$combine_end   = (\$block1_p->[1] > \$block2_p->[1]) ?  \$block1_p->[1] : \$block2_p->[1];

    my \$overlap_size = (\$block1_p->[1]-\$block1_p->[0]+1) + (\$block2_p->[1]-\$block2_p->[0]+1) - (\$combine_end-\$combine_start+1);

    return \$overlap_size;
}

(����overlap��Ҫ��ϵ������disposeOverlap.pl����Ҫ����
һ����Ϊ�߱����ֹ��ܾͿ��Դ�������overlap��ϵ���о�(Enumerate)���ϲ�(Combine)��ɸ��(Filterout)
1���о�
�оٵ���˼����������Ǵ��������ļ���������Ϊa�ļ���b�ļ������a,b)���������ļ�����һ����������(start,end)��Ϊ�Ƚϣ�
����Ҫ��b��������ж�����a�е�������overlap������a��Ϊ�ο�������a��ĳ�������b�ж��ٵ�������overlap�����г���
������a��b�ĸ�ʽΪ
Chromosome	RegionID	Start	End
����RegionID��Ϊ�������������־��һ��ID��Ҳ������������ļ�ʱoverlap�Ƚ�ʱ�趨Ϊ��ID��
�������ļ�����˼��,����ҵĲο��ļ�ֻ��a,�������b,c,d,e���ļ���overlap�Ƚϣ��ҿ��԰�b,c,d,e�ϲ�Ϊһ���ļ�B��Ȼ��ֱ���RegionID��־���Բ�ͬ�ļ���ӵ�е������Ա����֣��Ҿ�û��Ҫ��a�ļ�һ������b,c,d,e���Ƚ��ˣ���������Ҫ�õ����������Ƚϵ���Ϣ��
�������ջ��������ļ�֮��ıȽϡ�
��a����
chr1	a-1	10	100
��b��
chr1	b-1	1	20
chr1	b-2	20	40
chr1	b-3	80	120
chr1	b-4	1	1000
����overlap
��ô���Ǿ�Ҫ�õ���������Ϣ
ID      FirstTableID    Start   End     Length  OverlapNumber   OverlapSize     OverlapRate     SecondTableID:Start,End,Length,OverlapSize...
chr1    a-1     10      100     91      4       144     1.58241758241758        b-1:1,20,20,11  b-4:1,1000,1000,91      b-2:20,40,21,21	b-3:80,120,41,21
�������a-1����ĳ���ΪLength:91;
b-1(����20��a-1overlap����11),b-2(21,21),b-3(41,21),b-4��1000,91) #�����ڵ�һ����ֵ��b����ĳ��ȣ��ڶ�������a-1overlap�ĳ���;
�����������a-1overlap�ĳ���֮��ΪOverlapSize:144=11+21+21+91;
OverlapRate:OverlapSize/Length=1.58241758241758
Ȼ�����ǿ�����һЩ�޶���������disposeOverlap.pl�������޶���������"--OL"���ã����÷���Ϊ����ֵ-�޶�����������ֵ��
�޶������ֱ�Ϊ"big", "small", "first", "second", "bpsize"
"big"����˼��,ȡ���ֵΪ�ο�ֵ��:a-1��b-1�Ƚ�ʱ��a-1����ֵ��b-1�����Բο�ֵΪa-1�ĳ��ȣ���91;����a-1��b-4�Ƚ�ʱ����ȡb-4������Ϊ�ο�ֵ,��1000;
"small"�����big˵�ģ���ȡ������С���Ǹ���������ֱ�ȡb-1��a-1��
"first"���޶�ȡ��һ���ļ�����������������a-1��b�ļ��Ƚ�ʱ����ȡa-1���ο�������ѱ���a-1�󣬵���a-2��b�ļ����������Ƚ�ʱ����ȡa-2���ο���
"second"�����first˵�ģ���a-1��b�ļ��Ƚ�ʱ���ֱ���ȡ��b-1,b-2,b-3,b-4���ο���
��--OL���趨�����ǰ����ֵΪ0�����֪�ĸ��޶�������һ����,�޶���˼��:
���вο��޶�����ʱ���������¶�����overlap����"--OL 0.6-small"�����統a-1��b-1�Ƚ�ʱ������ȡsmallΪ�ο���b-1�Ĵ�СΪ�ο���
0.6����˼�����������overlap��СҪ����small size(�ο���b-1��С����50%��������b-1/a-1��ȻС��60%������b-1�Ͳ��������ˣ�
����a-1��b-4�Ƚ�ʱ������smallΪa-1�����ң�a-1��ȫ��������b-4�����a-1/a-1Ϊ100%>60%������b-4�����޶�������
���������������"--OL 0.5-small"����õ������Ľ����
ID      FirstTableID    Start   End     Length  OverlapNumber   OverlapSize     OverlapRate     SecondTableID:Start,End,Length,OverlapSize...
chr1    a-1     10      100     91      2       112     1.23076923076923        b-4:1,1000,1000,91      b-2:20,40,21,21
����������ǻ���һ���жϣ������ˡ�--OL����ֵ����0ʱ�����õ���a-1�ܵ�OverlapSize/Length(a-1���ȣ�����OverlapRateҲ������ڵ���60%��������Ϊ123%���ϡ�
�ڽű��п��������趨�޶�����������ֵ���������򽫲�����overlap�������ж���ֻҪ��overlap�������ˣ�ֻȡ���OverlapRate>=60%(ע�������ж��Ǵ��ڵ��ڣ���ô�õ��Ľ�������һ����ʾ�Ľ����
ID      FirstTableID    Start   End     Length  OverlapNumber   OverlapSize     OverlapRate     SecondTableID:Start,End,Length,OverlapSize...
chr1    a-1     10      100     91      4       144     1.58241758241758        b-1:1,20,20,11  b-4:1,1000,1000,91      b-2:20,40,21,21	b-3:80,120,41,21
��bpsize����ָ�޶���ÿ����overlap�ж�ʱ��Сoverlap�ĳ��ȣ��������衰--OL 40-bpsize",���ǵõ���
ID      FirstTableID    Start   End     Length  OverlapNumber   OverlapSize     OverlapRate     SecondTableID:Start,End,Length,OverlapSize...
chr1    a-1     10      100     91      1       91      1       b-4:1,1000,1000,91
�������ж�overlapʱ��b-1,b-2,b-3�ͱ����ˣ�������ʾ��a-1��overlap�ˡ�
��������ǲ�����overlap���޶���������������Ҫ�ܵ�OverlapSize����һ��ֵ��ֻҪ�衰numbp"�Ϳ����ˣ�num���޶�ֵ��С��������OverlapSize>=num bp��
�磺--OL 144bp,�����
ID      FirstTableID    Start   End     Length  OverlapNumber   OverlapSize     OverlapRate     SecondTableID:Start,End,Length,OverlapSize...
chr1    a-1     10      100     91      4       144     1.58241758241758        b-1:1,20,20,11  b-4:1,1000,1000,91      b-2:20,40,21,21     b-3:80,120,41,21
�����--OL 145bp,��Ϊ�����ݡ�
ID      FirstTableID    Start   End     Length  OverlapNumber   OverlapSize     OverlapRate     SecondTableID:Start,End,Length,OverlapSize...
����������Overlap�Ľ�������ڽű�������"--E O"�Ĺ��ܣ�
����������ʱ����Ҫ��������û��overlap,���Ϊȥ����Ľ�������Ҳ�Ҫa���ļ���b���ļ���overlap����Ϣ��
�����¶���һ�������ӣ�
a�ļ���
chr1	a-1	10	100
chr1	a-2	110	130
chr1	a-3	2000	2500
b�ļ�:
chr1	b-1	1	20
chr1	b-2	20	40
chr1	b-3	80	120
chr1	b-4	1	1000
���������"--OL 0"����:
ID      FirstTableID    Start   End     Length  OverlapNumber   OverlapSize     OverlapRate     SecondTableID:Start,End,Length,OverlapSize...
chr1    a-3     2000    2500    501     0       0       0
��Ϊֻ��a-3��b�ļ�������û��overlap��
����������޶���overlap��������"--OL 0.6-small"���ã�
ID      FirstTableID    Start   End     Length  OverlapNumber   OverlapSize     OverlapRate     SecondTableID:Start,End,Length,OverlapSize...
chr1    a-1     10      100     91      2       32      0.351648351648352       b-1:1,20,20,11  b-3:80,120,41,21
chr1    a-2     110     130     21      1       11      0.523809523809524       b-3:80,120,41,11
chr1    a-3     2000    2500    501     0       0       0
��Ϊb-1,b-3��a-1�Ƚ�ʱ��b-1��a-1��overlap��СΪ11,smallΪb-1��20��11/20<60%��b-3��a-1��overlap��СΪ21,smallΪb-3��41��21/41<60%����ˣ�b-1��b-3����overlap�޶������ڣ������г���
��b-2��b-4��overlap rate�ֱ�Ϊ:21/21=1>60%,91/91=1>60%�����Ա����ˡ�
a-3��b��û��������֮overlap�����Ե��С�
����ܵ�OverlapRate��<=60%�����Եý����

********************************************
ǿ����
--OL num-LimitType
num��limit����ֵ��������û��LimitType��󶼻�Ӱ���ܵ�OverlapRate��OverlapSize�ж��������ж�ȡ����(>=)
�����LimitType������overlap�����ж��������¶�����overlap�����Ǵ�ͳ��ΪֻҪ��1bp����Ϊoverlap�����Ǹ���num��Ϊ��ֵ�ж���
LimitType��,"big","small","first","second"���Ƕ�overlap rate�ıȽϣ�ֻ�ǲο���һ����
"bpsize"��"numbp"(numbp�ϸ���LimitType)��overlap size�ıȽ�,�����ο�ϵ��bpsize���ж�overlap���õ���numbp��ֻ�����OverlapSizeҪ���ڵ��ڵ���ֵ��
********************************************

������--E ����һ��"--mN"��ѡ�
��"--E O"��"--mN"�趨����ֵ��Ϊ��Сֵ������Ҫ�õ�b�ļ���СҪ�������ֵ���ϣ����������ֵ��СOverlapNum)��������a��ĳ������overlap�����������������ԣ�mNһ��ȡ���ڵ���1��
����"--E N"�У���ΪҪ�õ����Ƿ�������������У����ԣ�����Ҫ������С�ĵõ�overlap�����������������ֵ��Ϊ���е����ֵ������һ�����ֵ����ȡ���Բ����ڶ�ʧ��Ϣ����Ҳ��Ӧ������Ϊ�����OverlapNum����ȻOverlapSize��OverlapRateС����Ҳ˵���кܶ����ࡣ

�о�ʱ��Ϊ����CPUʱ�䣬�����
�Ƿ���overlap�ж�:
next if (E2<S1);
last if (S2>E1);

2���ϲ�
����˼�壬���ǰ���overlap������ϲ�������:
(1)���ཻ��:
S1********E1
     S2************E2
�ϲ���Ϊ����S1,E2��

S2************E2
         S1********E1
�ϲ���Ϊ����S2,E1��
(2)��������:
S2************E2
  S1*******E1
�ϲ���Ϊ��(S2,E2)

S1************E1
  S2*******E2
�ϲ���Ϊ��(S1,E1)

����������޶���overlap�����������¶�����overlap�Ͳ�����ô�򵥣�
��˼������ֻ�ϲ������Ƕ������overlap���������������͵����г���
��ʵ�ںϲ�������ܣ����ǿ��԰������ļ�����һ���ļ���������Ϊ����ֻҪ�������������򶼺ϲ��ˣ�����������overlap������"--C"Ҳ��һ��ȥ����Ĺ��ܡ�
��������--OL�е�"first","second"�Ͳ��������ˡ�
���ļ�c
chr1	c-1	1	20
chr1	c-2	20	40
chr1	c-3	30	60
chr1	c-4	50	100
���"--OL 0"���ã�
ID      Start   End     CombinedNum     CombinedTableID...
chr1    1       100     4       c-1     c-2     c-3     c-4
��Ϊ��c-1��c-2�ϲ���(1,40),�µ�������c-3�ϲ���(1,60)������c-4�ϲ���(1,100)��
��������"--OL 5-bpsize"������
ID      Start   End     CombinedNum     CombinedTableID...
chr1    1       20      1       c-1
chr1    20      100     3       c-2     c-3     c-4
��Ϊ--C�Ĺ����Ǵ������Һϲ��ģ���������޶���LimitType���ܻᵼ��һЩƫ���Դ𰸣������������start�����򣬺ϲ���һ���������һ������ǰ������ϲ�������бȽϣ���Ϊ��һ���������������ϲ���
���Ǽ����������¶�����overlap������������"--OL 0.5-small",���������
A*******************B
    c***********************************d
       e***************f
AB��һ���պϲ���block�������ж�AB��cd�Ƿ��ܺϲ�����Ȼ�����㡰--OL 0.5-big������������AB��cd���ܺϲ����������ڴ�ӡAB���½����²ο�cd����һ����ef����ȻefҲ�ǲ���������AB�ϲ��ġ�
�����������°���һ�£����AB��ef�ȱȽϣ�����OL��������ôAB��ef�ϲ���Af��Ȼ��Af��Ϊ�µĲο���cd�Ƚϣ�����Ҳ�ǿ�������OL����������Ad��
����������ô�С���������ǿ��Դﵽ���ϵ�Ч��������Ҫ�����㷨�ˡ�Ϊ�˼��ٳ���ĸ����ԣ�������ͼ򻯲���������㷨��
����Ȥ���Կ���һ�¡���˽���һ����LimitTypeΪ"--OL 0"��"bpsize"��û����ġ�

3��ɸ��
��������ɾ����overlap���������"--F R"����ȥ������һ���ļ���overlap������"--F D"��
��--F R���ǽ�һ���ļ��ڵ��������Ƚϣ���һЩoverlap������OL����������������ȥ����������Ҳ����start��������Ҳ�ᵼ����ƫ���Եģ��²ο�Ϊ�ϲ�����С����Ϊ��ϵ���ӣ�����һ�㽨����"--OL 0"��"--OL num-bpsize"��
��--F D���ǽ�һ���ļ�����һ���ļ����Ƚϣ������ڶ����ļ���������overlap���Ͱ�ԭ��һ�������overlapƬ��ɾ���������������Ƭ�Σ��磺
A*******************B��a�ļ���
    c***********************************d��b�ļ���
�ͻ�ʣAc��Bd��������������ڶ����ļ�������������࣬�磺
A*******************B��a�ļ���
    c***********************************d��b�ļ���
    ����e*********f��b�ļ���
�ͻᱨ��Ac��Bd��Ae��fB�ĸ���������ˣ����Խ�������Ȱ�a��b�ļ���һ�Ρ�--C����ȥ�����������--F D����

4����ȡoverlapƬ�κͷ�overlapƬ��
��--X [O|N]�������ǳ��������Ĺ��ܣ���Ҫ���ڰ�overlapƬ���������--X O�����磺
a*********b
    c*********d
�����overlapƬ�μ�Ϊcb��
���overlapȥ����ȥ�����Ƭ���������--X N�����磺
a*********b
    c*********d
����ķ�overlapȥ�����Ƭ�μ�Ϊac��bd��
�����ﲻ����OL����������ֻҪ��1bp����Ϊ��overlap��

5���������ܣ�
--M  ������ɸѡRegionID�õģ���������ʽƥ��ķ������ˡ��磺--M Variation���⴦��1��2�ļ���İ���Variation��ΪRegionID�Ŀ顣���--M 1,Variation:2,mRNA��������1�е�Variation��2�е�mRNA�Ƚϣ�һ�㲻�����á�
��:����--M 1,"^Variation\$":2,mRNA
--interpolation �����ڶ��ļ��ģ���Ϊ��Щ�ļ����ÿո���еģ���Щ�ļ�����tab���еģ����б�ģ�����--interprolationѡ�����ã���--interprolation s+���൱�ڶ��ļ���split /\\s+/�Ĺ��ܣ�Ĭ����s+��һ�㲻�����á�

for JiJi
2008-12-16

********************************************
����:3.2�汾��,"--OL"��������������limite����,��ֻ��overlap����,����������������,��:
"--OL 0.6-small"����˼ֻ������blocks��overlap����,�����Ҫ�ܵ�OverlapRate>=0.6 of the block size of first table,�����Ҫ����һ��,ֻ�����"--final".
�����˱����Ż�.
********************************************

********************************************
3.3��汾��,��"--E O"�Ĺ����У������Limit-type: "big", "small", "first", "second","bpsize"���Ӱ��overlap���ض��壬��ÿ��blocks��overlap�Ƚϣ����ᰴ�˶������޶���������ֻ�м���"--final"���Ż�Ӱ���������������޶����ϡ�
�����û��Limit-type������overlap���ض��壬�����������ļ���ÿ��������бȽ�ֻҪ��1bp��overlap������overlap������ʹ������"--final"������������֣���"--OL 0.1"����ɸѡ���OverlapRate>=0.1�Ľ�������
�����"--OL 10bp"������ɸѡOverlapSize>=10�Ľ���������Ȼ"--E N"�����������պ��෴��
��ôOL�����������¼��ֲ�ͬ������:
"--OL 0.1":  ֻ�޶�����OverlapRate����overlap����ʱֻҪ��1bp����;
"--OL 0.1-small":  �޶�overlap�Ƚ�����������������ֻ�е�overlap��С������С���򳤶ȵ�10%����Ϊ��overlap�������������޶�OverlapRate;
"--OL 0.1-small -final":  �Ƚ϶���overlapʱͬ--OL 0.1-small�����������޶�OverlapRate>=0.1���������������OverlapRate=OverlaSize/Length (title���ֵ);
"--OL 10bp":  ֻ�޶�����OverlapSize, ��overlap����ʱֻҪ��1bp����;
"--OL 10-bpsize": �޶�overlap�Ƚ�����������������ֻ�е�overlap��С���ڣ�������)10����Ϊ��overlap�������������޶�OverlapSize;
--OL 10-bpsize -final  �Ƚ϶���overlapʱͬ--OL 10-bpsize�����������޶�OverlapSize>=10�����;
����OverlapRate,OverlapSize,Length����title��ֵ��Ϊ�ܵ�Overlap���ʣ��ܵ�Overlap��С���͵�һ�ļ�������ĳ���
����������С�޸ģ��Ժ���Ե�һ���ļ�����λ����Ϊ�����(����)�б��ڶ����ļ���֮overlap���ᰴoverlap��С�Ӵ�С�ں����оٳ���

��������賿2:39am, Happy ţ Year!
********************************************

USAGE
    print $usage;
}
