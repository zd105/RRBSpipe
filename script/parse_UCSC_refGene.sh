#!/bin/sh
if [ $# != 4 ]
then
    echo "----------------------------------------------------------"
    echo "Usage: $0 <reference genome> <UCSC_refGene.txt[.gz]> <outdir> <prefix_of_output>"
    echo "Use this perl to get following files from UCSC-refGene.txt:"
    echo "1. exon.bed"
    echo "2. cds.bed"
    echo "3. intron.bed"
    echo "4. intergenic.bed"
    echo "5. 5utr.bed"
    echo "6. 3utr.bed"
    echo "7. up2k.bed"
    echo "8. down2k.bed"
    echo "9. TSS.bed"
	echo "10. promoter.bed"
    echo "11. genebody.bed"
    echo "12. up1k.bed"
	echo "13. down1k.bed"
	echo "14. up5k.bed"
	echo "15. down5k.bed"
    echo "----------------------------------------------------------"
    exit
########################## format of refGene.txt.gz from UCSC (tab splited)######################
#bin   transcriptName  chrom   strand  transcriptStart   transcriptEnd   cdsStart   cdsEnd   exonCount   exonStarts          exonEnds            score  geneName         cdsStartStat   cdsEndStat   exonFrames
#944   NM_001357077    chr1    +       47140242          47141166        47140242   47140776 2           47140242,47141151,  47140863,47141166,  0      LOC111258524  cmpl           cmpl         0,-1,

#================= perl column number ============
#0     1               2       3       4                 5               6          7        8           9                   10                  11     12             13            14           15

########################## output bed file format ###################
#chrom   Start      End        transcriptName  geneName      strand
#chr1    47140242   47141166   NM_001357077    LOC111258524  +

fi
genome=$1
ref=$2
outdir=$3
prefix=$4

##### genome prepare
echo "|-- $genome preparing..."
samtools faidx $genome
cut -f-2 $genome.fai > $genome.length
#slopBed -i $name.cgi.bed -g $ref.length -b 2000 | mergeBed | subtractBed -a - -b $name.cgi.bed > $name.cgi_shore.bed

#####0 TSS
echo "|-- $prefix.tss.bed begin..."
less -S $ref | perl -alne 'if($F[4]==0){next};if($F[3] eq "+"){ print join "\t", @F[2,4], @F[4,1,12,3]; }else{print join "\t", @F[2,5], @F[5,1,12,3];}' | sort -k1,1 -k2,2n > $outdir/$prefix.tss.bed
echo "--| $prefix.tss.bed is done..."

##### promoter (-2k~+500)
echo "|-- $prefix.promoter.bed begin..."
slopBed -i $outdir/$prefix.tss.bed -g $genome.length -l 2000 -r 500 -s >  $outdir/$prefix.promoter.bed
echo "|-- $prefix.promoter.bed is done..."

#####1 genebody
echo "|-- $prefix.genebody.bed begin..."
less -S $ref | perl -alne 'print join "\t", @F[2,4,5,1,12,3];' | sort -k1,1 -k2,2n > $outdir/$prefix.genebody.bed
echo "--| $prefix.genebody.bed is done..."

#####2 intergenic
echo "|-- $prefix.intergenic.bed begin..."
sort -k1,1 -k2,2n -u $prefix.genebody.bed | perl -alne ' $g="$F[3];$F[4];$F[5]"; $end=$F[2]; if($F[0] eq $tem_chr){ print $F[0],"\t", $tem_end+1,"\t", $F[1]-1,"\t", $tem_gene,"\t", $g; } $tem_gene=$g; $tem_end=$end; $tem_chr=$F[0];' | perl -alne 'print if $F[2]-$F[1]>1000' | sort -k1,1 -k2,2n > $outdir/$prefix.intergenic.bed
echo "--| $prefix.intergenic.bed is done..."

####3 up2k
echo "|-- $prefix.up2k.bed begin..."
cat $prefix.genebody.bed | perl -alne 'if($F[5] eq "+"){ print join "\t",$F[0],$F[1]-2000, $F[1]-1, @F[3,4,5] }else{print join "\t",$F[0], $F[2]+1, $F[2]+2000,@F[3,4,5]}' > $outdir/$prefix.up2k.bed
echo "--| $prefix.up2k.bed is done..."

####3 up1k
echo "|-- $prefix.up1k.bed begin..."
cat $prefix.genebody.bed | perl -alne 'if($F[5] eq "+"){ print join "\t",$F[0],$F[1]-1000, $F[1]-1, @F[3,4,5] }else{print join "\t",$F[0], $F[2]+1, $F[2]+1000,@F[3,4,5]}' > $outdir/$prefix.up1k.bed
echo "--| $prefix.up1k.bed is done..."

###4 down2k
echo "|-- $prefix.down2k.bed begin..."
cat $prefix.genebody.bed | perl -alne 'if($F[5] eq "+"){ print join "\t",$F[0],$F[2]+1, $F[2]+2000, @F[3,4,5] }else{print join "\t",$F[0], $F[1]-2000, $F[1]-1,@F[3,4,5]}' > $outdir/$prefix.down2k.bed
echo "--| $prefix.down2k.bed is done..."

###4 down1k
echo "|-- $prefix.down1k.bed begin..."
cat $prefix.genebody.bed | perl -alne 'if($F[5] eq "+"){ print join "\t",$F[0],$F[2]+1, $F[2]+1000, @F[3,4,5] }else{print join "\t",$F[0], $F[1]-1000, $F[1]-1,@F[3,4,5]}' > $outdir/$prefix.down1k.bed
echo "--| $prefix.down1k.bed is done..."

####5 exon
echo "|-- $prefix.exon.bed begin..."
less -S $ref | perl -F"\t" -alne '@a=split(/,/,$F[9]);
    @b=split(/,/,$F[10]);
    if($F[3] eq "+"){
        foreach $i (0..$#a){
                if($F[1]=~/;/){@f=split(/;/,$F[1]);$F[1]=$f[0]};
                print join "\t", $F[2],$a[$i],$b[$i],$F[1],$F[12],$F[3];
        }
    }
    else{
        foreach $i (0..$#a){
                if($F[1]=~/;/){@f=split(/;/,$F[1]);$F[1]=$f[0]};
                print join "\t", $F[2],$a[$i],$b[$i],$F[1],$F[12],$F[3];
            }
    } ' | sort -k1,1 -k2,2n > $outdir/$prefix.exon.bed
echo "--| $prefix.exon.bed is done..."

####5.1 first exon
echo "|-- $prefix.exon1.bed begin..."
less -S $ref | perl -F"\t" -alne '@a=split(/,/,$F[9]);
	@b=split(/,/,$F[10]);
	if($F[3] eq "+"){
		foreach $i (0..$#a){
			if($i==0){print join "\t", $F[2],$a[$i],$b[$i],$F[1],$F[12],$F[3],exon1;}
		}
	}
	else{
		foreach $i (0..$#a){
			if($i==$#a){
				print join "\t", $F[2],$a[$i],$b[$i],$F[1],$F[12],$F[3],exon1;
			}
		}
	} ' | sort -k1,1 -k2,2n > $outdir/$prefix.exon1.bed

#####6 intron
echo "|-- $prefix.intron.bed begin..."
less -S $ref | perl -F"\t" -alne '@a=split(/,/,$F[9]);
    @b=split(/,/,$F[10]);
    next if @a==1;
    if($F[3] eq "+"){
        foreach $i (0..($#b-1)){
            next if ($b[$i]+1) > ($a[$i+1]-1);
            if($i==0){
				print join "\t", $F[2],$b[$i]+1,$a[$i+1]-1,$F[1],$F[12],$F[3];
                #print join "\t", $F[2],$b[$i]+1,$a[$i+1]-1,$F[1],$F[12],$F[3],intron1;
            }
            else{
                print join "\t", $F[2],$b[$i]+1,$a[$i+1]-1,$F[1],$F[12],$F[3];
            }
        }
    }
    else{
        foreach $i (0..($#b-1)){
            next if ($b[$i]+1) > ($a[$i+1]-1);
            if($i==($#b-1)){
                #print join "\t", $F[2],$b[$i]+1,$a[$i+1]-1,$F[1],$F[12],$F[3],intron1;
				print join "\t", $F[2],$b[$i]+1,$a[$i+1]-1,$F[1],$F[12],$F[3];
            }
            else{
                print join "\t", $F[2],$b[$i]+1,$a[$i+1]-1,$F[1],$F[12],$F[3];
            }
        }
    }' | sort -k1,1 -k2,2n > $outdir/$prefix.intron.bed
echo "--| $prefix.intron.bed is done..."

#####6.1 first intron
echo "|-- $prefix.intron1.bed begin..."
less -S $ref | perl -F"\t" -alne '@a=split(/,/,$F[9]);
@b=split(/,/,$F[10]);
next if @a==1;
if($F[3] eq "+"){
    foreach $i (0..($#b-1)){
    next if ($b[$i]+1) > ($a[$i+1]-1);
    if($i==0){
		    #print join "\t", $F[2],$b[$i]+1,$a[$i+1]-1,$F[1],$F[12],$F[3],intron1;
	}
	}
}else{
	foreach $i (0..($#b-1)){
		next if ($b[$i]+1) > ($a[$i+1]-1);
		if($i==($#b-1)){
			print join "\t", $F[2],$b[$i]+1,$a[$i+1]-1,$F[1],$F[12],$F[3],intron1;
         }
    }
	}' | sort -k1,1 -k2,2n > $outdir/$prefix.intron1.bed

####7 cds
echo "|-- $prefix.cds.bed begin..."
less -S $ref | perl -F"\t" -alne '@a=split(/,/,$F[9]);
    @b=split(/,/,$F[10]);
    $st = $F[6];
    $end = $F[7];
    foreach $i (0..$#a){
        $s = $a[$i];
        $e = $b[$i];
        next if $e < $st || $s > $end;
        @arr = sort { $a<=>$b }($st, $end, $s, $e);
        print join "\t", $F[2],$arr[1],$arr[2],$F[1],$F[12],$F[3];
    } ' | sort -k1,1 -k2,2n > $outdir/$prefix.cds.bed
echo "--| $prefix.cds.bed is done..."

####8  5utr
echo "|-- $prefix.5utr.bed begin..."
less -S $ref | perl -F"\t" -alne '@a=split(/,/,$F[9]);
    @b=split(/,/,$F[10]);
    $st = $F[6];
    $end = $F[7];
    if($F[3] eq "+"){
        foreach $i (0..$#a){
            $s = $a[$i];
            $e = $b[$i];
            if( $st>=$s && $st <=$e){
                print join "\t",$F[2], $s, $st, $F[1], $F[12], $F[3];
            }
        }
    }
    else{
        foreach $i (0..$#a){
            $s = $a[$i];
            $e = $b[$i];
            if( $end>=$s && $end <=$e){
                print join "\t", $F[2], $end, $e, $F[1], $F[12], $F[3];
            }
        }
    }' | perl -alne 'print if $F[2]-$F[1]>1' | sort -k1,1 -k2,2n > $outdir/$prefix.5utr.bed
echo "--| $prefix.5utr.bed is done..."

####9 3utr
echo "|-- $prefix.3utr.bed begin..."
less -S $ref | perl -F"\t" -alne '@a=split(/,/,$F[9]);
    @b=split(/,/,$F[10]);
    $st = $F[6];
    $end = $F[7];
    if($F[3] eq "+"){
        foreach $i (0..$#a){
            $s = $a[$i];
            $e = $b[$i];
            if( $end>=$s && $end <=$e){
                print join "\t",$F[2], $end, $e, $F[1], $F[12], $F[3];
            }
        }
    }
    else{
        foreach $i (0..$#a){
            $s = $a[$i];
            $e = $b[$i];
            if( $st>=$s && $st <=$e){
                print join "\t", $F[2], $s, $st, $F[1], $F[12], $F[3];
            }
        }
    }' | perl -alne 'print if $F[2]-$F[1]>1' | sort -k1,1 -k2,2n > $outdir/$prefix.3utr.bed
echo "--| $prefix.3utr.bed is done..."
####
